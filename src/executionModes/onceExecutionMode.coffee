BaseExecutionMode = require "./baseExecutionMode"

module.exports =
  class OnceExecutionMode extends BaseExecutionMode
    start: (reader) => 
      @executeOnce(reader)
      .tap () => reader.emit "job-finish"
      .tap () => process.exit 0

    handleError: (err, reader, keepAliveMessage, message) ->
      super err, reader, keepAliveMessage, message
      .then () => 
        reader.emit "job-error-finish"
        process.exit 1


