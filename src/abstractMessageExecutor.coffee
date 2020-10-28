_ = require "lodash"
Promise = require "bluebird"
MaxRetriesExceededException = require "./maxRetriesExceededException"
debug = require("debug")("long-task-queue-reader:message-executor")

module.exports =
  class AbstractMessageExecutor
    constructor: ({ @runner, @message, @maxRetries, @fromPoison } = {}) ->

    execute: ->
      body = @_body_()
      debug "Processing %o", body
      return Promise.reject(new MaxRetriesExceededException(@message, @maxRetries)) if @hasReachedMaxRetries() and not @fromPoison
      Promise.method(@runner) body

    hasReachedMaxRetries: =>
      @_receiveCount_() > @maxRetries 

    _body_: () -> throw new Error "not_implemented"

    _receiveCount_: () -> throw new Error "not_implemented"