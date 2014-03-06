# Description
#   Write and read thoughtbot news.
#
# Commands:
#   /news <story>. - Returns nothing. Records the news.

class BotTimes
  FOUR_HOURS: 14400 * 1000

  constructor: (robot) ->
    @robot = robot
    @data = @robot.brain.data
    @campfireRoom = process.env.EVERYONE_CAMPFIRE_ROOM or 'Shell'

  writeNews: (msg) ->
    @data['news'].push msg

  deliver: =>
    @robot.messageRoom @campfireRoom, @data['news']...
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

    # /news Derek is now the open source leader of Clearance. Thank you!
    robot.respond /news (.+)/i, (msg) ->
      theTimes.writeNews msg.match[1]
      msg.send "Word. I'll relay that every four hours or so over the next day."
