{ AppendBlobClient, StorageSharedKeyCredential } = require "@azure/storage-blob"
Transport = require "winston-transport"

class AzureBlobStorageTransport extends Transport
  constructor: ({ level }, @_blobClient) ->
    super { level }

  log: (info, callback) ->
    line = JSON.stringify(info) + "\n"
    buf = Buffer.from line
    @_blobClient.appendBlock(buf, buf.length)
      .then =>
        @emit "logged", info
        callback()
      .catch callback

module.exports =
  class AzureLogger

    constructor: ({@accountName, @accountKey, @container, @name, @level = "info"}) ->
      credential = new StorageSharedKeyCredential @accountName, @accountKey
      @_blobClient = new AppendBlobClient(
        "https://#{@accountName}.blob.core.windows.net/#{@container}/#{@name}",
        credential
      )
      @_transport = new AzureBlobStorageTransport { level: @level }, @_blobClient

    initialize: ->
      @_blobClient.createIfNotExists()

    transport: -> @_transport
