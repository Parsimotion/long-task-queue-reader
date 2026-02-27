BaseExecutionMode = require "./baseExecutionMode"

module.exports =
  class OnceExecutionMode extends BaseExecutionMode
    start: (reader) => 
      @executeOnce(reader)
      .tap () => reader.emit "job-finish"
      .tap () => process.exit 0

