assert = require "assert"
sinon = require "sinon"
lightning = require "../scripts/lightning"

describe 'Lightning talks', ->
  it 'sends the correct message', ->
    messageSpy = sinon.spy()
    responder = (regex, action) ->
      messageStub = { send: messageSpy }
      action(messageStub)

    lightning({respond: responder})
    assert(messageSpy.calledWith('lightning, yeah greased lightning'))
