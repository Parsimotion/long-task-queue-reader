BaseExecutionMode = require "./baseExecutionMode"

module.exports =
  class OnceExecutionMode extends BaseExecutionMode
    start: (reader) => @executeOnce(reader)

