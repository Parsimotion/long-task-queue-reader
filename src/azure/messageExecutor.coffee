_ = require "lodash"
Promise = require "bluebird"
convert = require "convert-units"

debug = require("debug")("long-task-queue-reader:message-executor")

module.exports =
  class AzureMessageExecutor
    constructor: ({ @runner, @message, @maxRetries } = {}) ->

    execute: ->
      debug "Processing %o", @message.messageText
      return Promise.reject(new MaxRetriesExceededException(@message, @maxRetries)) if @hasReachedMaxRetries()
      Promise.method(@runner) @message.messageText

    hasReachedMaxRetries: =>
      @message.dequeueCount > @maxRetries 
