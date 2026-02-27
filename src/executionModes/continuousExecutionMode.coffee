BaseExecutionMode = require "./baseExecutionMode"

module.exports =
  class ContinuousExecutionMode extends BaseExecutionMode
    start: (reader) ->
      @executeOnce(reader)
      .then (message) =>
        setTimeout (=> @start(reader)), @_nextTimeout(reader, message)
        return

