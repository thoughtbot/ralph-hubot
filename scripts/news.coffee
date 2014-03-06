# Description
#   Write and read thoughtbot news.
#
# Commands:
#   /pitch <story>. - Returns nothing. Records the news.

class BotTimes
  FOUR_HOURS: 14400 * 1000

  constructor: (robot) ->
    @robot = robot
    @data = @robot.brain.data

  pitch: (msg) ->
    @data['news'].push msg

  deliver: =>
    @robot.messageRoom 'Everyone', @data['news']...
    @_trimToNewestEightyPercent()

    setTimeout () =>
      @deliver()
    , @FOUR_HOURS

  _trimToNewestEightyPercent: ->
    twentyPercentIndex = @data['news'].length * 0.2
    @data['news'] = @data['news'][twentyPercentIndex..-1]

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    theTimes = new BotTimes(robot)
    theTimes.deliver()

    # /pitch Derek is now the open source leader of Clearance. Thank you!
    robot.respond /pitch (.+)/i, (msg) ->
      theTimes.pitch msg.match[1]
      msg.send "Word. I'll relay that every four hours or so over the next day."
