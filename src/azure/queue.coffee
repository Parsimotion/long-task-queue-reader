_ = require "lodash"
{ QueueServiceClient, StorageSharedKeyCredential } = require "@azure/storage-queue"
Promise = require "bluebird"
retry = require "bluebird-retry"

debug = require("debug")("long-task-queue-reader:queue")

encode = (message) -> Buffer.from(String(message)).toString("base64")
decode = (text) -> Buffer.from(text, "base64").toString("utf-8")

module.exports =
  class Queue

    constructor: ({accountKey, accountName, queueName, name}) ->
      @queueName = queueName or name
      @_serviceClient = @_buildServiceClient accountName, accountKey

    initialize: => Promise.map [ @queueName, @_poisonQueueName() ], @create

    create: (queueName) =>
      Promise.resolve @_getQueueClient(queueName).createIfNotExists()

    sendToPoison: (message) ->
      @pushPoison message.messageText

    messages: (opts = {}) ->
      Promise.resolve(@_getQueueClient(@queueName).receiveMessages {
        numberOfMessages: opts.maxMessages or 1,
        visibilityTimeout: opts.visibilityTimeout or 30
      })
      .then (result) ->
        messages = result.receivedMessageItems.map (item) ->
          _.assign {}, item, messageText: decode item.messageText
        debug "Received Messages: %o", _.map(messages, "messageText")
        messages

    update: (timeout, {messageId, popReceipt, messageText}) ->
      debug "Updating [timeout: #{timeout}, messageId: #{messageId}, popReceipt: #{popReceipt}, messageText: #{JSON.stringify messageText}]"
      Promise.resolve(@_getQueueClient(@queueName).updateMessage messageId, popReceipt, encode(messageText), timeout)
      .tap (message) -> debug "Updated message: %o", message

    remove: ({messageId, popReceipt}) ->
      debug "Removing message: [messageId: #{messageId}, popReceipt: #{popReceipt}]"
      retry () => @_getQueueClient(@queueName).deleteMessage messageId, popReceipt
      .tap -> debug "Removed messageId: #{messageId}"

    push: (message) -> @_push @queueName, message

    pushPoison: (message) -> @_push @_poisonQueueName(), message

    _push: (queueName, message) =>
      @_getQueueClient(queueName).sendMessage encode(message)

    _poisonQueueName: -> "#{@queueName}-poison"

    _getQueueClient: (queueName) -> @_serviceClient.getQueueClient queueName

    _buildServiceClient: (accountName, accountKey) ->
      credential = new StorageSharedKeyCredential accountName, accountKey
      new QueueServiceClient "https://#{accountName}.queue.core.windows.net", credential
