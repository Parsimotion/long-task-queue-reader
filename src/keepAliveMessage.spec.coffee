_ = require "lodash"
sinon = require "sinon"
Promise = require "bluebird"
should = require "should"
convert = require "convert-units"
KeepAliveMessage = require "./keepAliveMessage"

require "should-sinon"

describe "KeepAliveMessage", ->

  { keepAliveMessage, clock, touch } = {}

  beforeEach ->
    touch = sinon.spy -> Promise.resolve()
    keepAliveMessage = new KeepAliveMessage { id: "messageId" }, 10, touch
    clock = sinon.useFakeTimers()

  afterEach ->
    clock.restore()

  it "should not push a new touch", ->
    keepAliveMessage.start()
    nextTime = convert(4).from("s").to("ms")
    clock.tick nextTime

    keepAliveMessage.q.length().should.be.eql 0

  it "should call touch", (done) ->
    keepAliveMessage.start()
    keepAliveMessage.q.drain = ->
      touch.should.be.calledTwice()
      done()

    nextTime = convert(12).from("s").to("ms")
    clock.tick nextTime

    keepAliveMessage.q.length().should.be.eql 2
