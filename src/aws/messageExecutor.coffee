_ = require "lodash"
Promise = require "bluebird"
convert = require "convert-units"
MaxRetriesExceededException = require "../maxRetriesExceededException"
debug = require("debug")("long-task-queue-reader:message-executor")

module.exports =
  class AwsMessageExecutor
    constructor: ({ @runner, @message, @maxRetries } = {}) ->

    execute: ->
      debug "Processing %o", @message.Body
      return Promise.reject(new MaxRetriesExceededException(@message, @maxRetries)) if @hasReachedMaxRetries()
      Promise.method(@runner) @message.Body

    hasReachedMaxRetries: =>
      parseInt(@message.Attributes.ApproximateReceiveCount) > @maxRetries 
