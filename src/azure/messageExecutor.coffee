_ = require "lodash"
Promise = require "bluebird"
convert = require "convert-units"

debug = require("debug")("long-task-queue-reader:message-executor")

module.exports =
  class AzureMessageExecutor
    constructor: (@runner, @message) ->
    execute: ->
      #jobId must decrement in order to be sorted by date desc by azure tables
      opts = _.merge {}, @message.messageText, { id: @_generateIdByDate() }
      debug "Processing %o", opts
      Promise.method(@runner) opts

    _generateIdByDate: ->
      id = 100000000 * convert(24).from("h").to("ms") - new Date().getTime()
      id.toString()
