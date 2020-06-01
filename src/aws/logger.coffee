winston = require "winston"
Promise = require "bluebird"
azure = require "azure-storage"
debug = require("debug")("long-task-queue-reader:logger")

require "winston-azure-blob-transport"

module.exports =
  class AzureLogger

    constructor: ({@accountName, @accountKey, @container, @name, @level = "info"}) ->
      @_transport = new (winston.transports.AzureBlob)
        account:
          name: @accountName
          key: @accountKey
        containerName: @container
        blobName: @name
        level: @level

    initialize: -> @_transport.initialize()

    transport: -> @_transport