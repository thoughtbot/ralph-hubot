# Description:
#   Save messages of the format "Joe: check out this link". The message must
#   start with (e.g.) "Joe: " or "Joe, ". It then reprints the messages when Joe
#   comes back into the room.
#
# Dependencies:
#   * A robot.brain that saves to persistent storage. I've only tested this with
#     redis-brain (available by default)
#   * Underscore.js
#
# Configuration:
#   * Ensure your brain's persistent storage is set up (e.g. RedisToGo on Heroku).

_ = require 'underscore'

class FutureMessager
  constructor: (robot) ->
    @brain = robot.brain
    @brain.data.futureMessages ?= {}
    @messages = @brain.data.futureMessages

  maybeSaveForLater: (msg, targetUser) ->
    if @targetUserNotInRoom(targetUser)
      sender = msg.message.user.name
      msg.send "#{sender}, #{targetUser} isn't in the room, but I'll relay that message when they come back."
      @saveForLater(msg, targetUser)

  saveForLater: (msg, targetUser) ->
    sender = msg.message.user.name
    room = msg.message.user.room
    @messages[room] ?= {}
    @messages[room][targetUser] ?= []
    @messages[room][targetUser].push(@textForLater(msg.message.text, sender))

  textForLater: (text, sender) ->
    timestamp = (new Date()).toLocaleString()
    "[#{timestamp}] From: #{sender} | #{text}"

  tellUserAboutMissedMessages: (msg) ->
    newlyEnteredUsername = msg.message.user.name
    room = msg.message.user.room

    if @messages[room]?
      # Scan stored matches for newly-entered user
      resultOfScanningForPings = @fuzzyIsInList(newlyEnteredUsername, _.keys(@messages[room]))
      if resultOfScanningForPings.length > 0
        sentNotification = false
        for previouslyPingedUsername in resultOfScanningForPings
          if @messages[room][previouslyPingedUsername].length > 0
            if sentNotification is false
              # Notify them that they have some messages coming up
              msg.send "Hey #{newlyEnteredUsername}, you have some messages:"
              sentNotification = true
          @messages[room][previouslyPingedUsername].sort()
          for pastMessage in @messages[room][previouslyPingedUsername]
            msg.send "> #{pastMessage}"
          @messages[room][previouslyPingedUsername] = []

  targetUserNotInRoom: (targetUser) ->
    ! @fuzzyIsInList(targetUser, @usernamesInRoom())

  usernamesInRoom: ->
    user.name.toLowerCase() for own key, user of @brain.data.users

  # Find names in the possibleUsernames that start with the given nickname.
  fuzzyIsInList: (nickname, possibleUsernames) ->
    lowerNickname = nickname.toLowerCase()
    username for username in possibleUsernames when (
      lowerNickname.toLowerCase().lastIndexOf(username, 0) is 0
    )

module.exports = (robot) ->
  # Ensure the brain is loaded.
  robot.brain.on 'loaded', ->
    futureMessager = new FutureMessager(robot)

    # Listen for messages like "Joe: tell me a joke". The username must start
    # the message.
    robot.hear /^([a-z ë]+)[,:]/i, (msg) ->
      targetUser = msg.match[1].toLowerCase()
      futureMessager.maybeSaveForLater(msg, targetUser)

    # When a user enters, tell them about the messages they missed.
    robot.enter (msg) ->
      futureMessager.tellUserAboutMissedMessages(msg)
