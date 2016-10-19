_ = require "lodash"
Promise = require "bluebird"
convert = require "convert-units"

debug = require("debug")("long-task-queue-reader:message-executor")

module.exports =
  class AzureMessageExecutor
    constructor: (@runner, @message) ->
    execute: ->
      debug "Processing %o", @message.messageText
      Promise.method(@runner) @message.messageText