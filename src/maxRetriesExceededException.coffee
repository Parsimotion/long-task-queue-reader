module.exports =
  class MaxRetriesExceededException extends Error
    constructor: (message, maxRetries) ->
      @data = message
      @message = "Can't retry this message anymore, kept failing after #{maxRetries} retries"
