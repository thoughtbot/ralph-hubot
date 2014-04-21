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
    @data['news'] ?= []
    @campfireRoom = process.env.EVERYONE_CAMPFIRE_ROOM or 'Shell'

  writeNews: (msg) ->
    @data['news'].push msg

  deliver: ->
    setTimeout () =>
      if @data['news'].length > 0
        @robot.messageRoom @campfireRoom, @data['news']...
      @_trim()
      @deliver()
    , @FOUR_HOURS

  _trim: ->
    if @data['news'].length is 1
      @data['news'] = []
    else if @data['news'].length <= 6
      @_trimOldestPercent(0.5)
    else
      @_trimOldestPercent(0.33)

  _trimOldestPercent: (percentage) ->
    index = @data['news'].length * percentage
    @data['news'] = @data['news'][index..-1]

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    robot.news = new BotTimes(robot)
    robot.news.deliver()

    # /news Derek is now the open source leader of Clearance. Thank you!
    robot.respond /news (.+)/i, (msg) ->
      robot.news.writeNews msg.match[1]
      msg.send "Word. I'll relay that every four hours or so over the next day."

  # curl \
  #   -XPOST \
  #   'http://ralph.thoughtbot.com/news' \
  #   -H'Content-Type: application/json'
  #   --data-binary '{"message":"Hello"}'
  robot.router.post '/news', (req, res) ->
    message = req.body.message
    robot.news.writeNews message
    res.status(201).send()
