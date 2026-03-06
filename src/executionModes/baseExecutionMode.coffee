_ = require "lodash"
convert = require "convert-units"

module.exports =
  class BaseExecutionMode

    _getMessage: (reader) ->
      reader.emit "job-get-messages"
      reader.queue.messages {
        maxMessages: 1,
        visibilityTimeout: reader.visibilityTimeout
      }
      .get 0
    
    executeOnce: (reader) ->
      @_getMessage(reader)
      .tap (message) => reader._execute(message) if message?
      .tap => reader.emit "job-finish-messages"
      .catch (err) => reader.emit "job_error", { method: "executionMode._executeOnce", err }

    _nextTimeout: (reader, message) ->
      if _.isEmpty message then convert(reader.waitingTime).from("s").to("ms") else 0

