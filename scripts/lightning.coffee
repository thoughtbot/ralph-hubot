# Description:
#   Allows Hubot to write lightning talks.
#
# Commands:
#   hubot lightning - Writes a lightning talk for you.

module.exports = (robot) ->
  robot.respond /lightning/, (msg) ->
    msg.send 'lightning, yeah greased lightning'
