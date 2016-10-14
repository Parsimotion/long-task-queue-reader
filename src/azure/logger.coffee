winston = require "winston"
Promise = require "bluebird"
azure = require "azure-storage"
debug = require("debug")("long-task-queue-reader:logger")

require "winston-azure-blob-transport"

module.exports =
  class AzureLogger

    constructor: ({@accountName, @accountKey, @container, @name, @level = "info"}) ->

    initialize: ->
      Promise.promisifyAll azure.createBlobService @accountName, @accountKey
      .createContainerIfNotExistsAsync @container, publicAccessLevel: "blob"
      .then (created) => debug "Container: #{@container} - #{if created then 'creada' else 'existente'}"

    transport: ->
      new (winston.transports.AzureBlob)
        account:
          name: @accountName
          key: @accountKey
        containerName: @container
        blobName: @name
        level: @level