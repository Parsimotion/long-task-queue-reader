async = require "async"
convert = require "convert-units"
retry = require "bluebird-retry"

module.exports =
  class KeepAliveMessage

    constructor: (@message, @visibilityTimeout, @touch) ->
      @q = @_buildQueue()

    start: =>
      @intervalHandler = setInterval (=>
        @q.push 1
      ), @_timeToTouch()

    destroy: =>
      throw new Error "should call to start before" unless @intervalHandler?
      @q.kill()
      clearInterval @intervalHandler

    _buildQueue: =>
      async.queue (task, callback) =>
        @_callToTouch().finally -> callback()

    _callToTouch: => retry () => @touch @message

    _timeToTouch: => convert(@visibilityTimeout).from("s").to("ms") / 2