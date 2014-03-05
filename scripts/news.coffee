# Description
#   Write and read thoughtbot news.
#
# Commands:
#   /pitch <story>. - Returns nothing. Records the news.

class BotTimes
  FOUR_HOURS: 14 * 1000

  constructor: (robot) ->
    robot.brain.data.news ?= []
    @news = robot.brain.data.news

  pitch: (msg) ->
    @news.push(msg)

  deliver: (robot) =>
    robot.messageRoom('Everyone', @news...)
    @news = @_newestEightyPercentOf(@news)

    setTimeout () =>
      @deliver(robot)
    , @FOUR_HOURS

  _newestEightyPercentOf: (array) ->
    twentyPercentIndex = array.length * 0.2
    array[twentyPercentIndex..array.length]

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    theTimes = new BotTimes(robot)
    theTimes.deliver(robot)

    # /pitch Derek is now the open source leader of Clearance. Thank you!
    robot.respond /pitch (.+)/i, (msg) ->
      theTimes.pitch(msg.match[1])
