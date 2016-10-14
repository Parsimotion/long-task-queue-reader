_ = require "lodash"
AzureQueueNode = require "azure-queue-node"
Promise = require "bluebird"
azure = include("config/environment").azure

debug = require("debug")("long-task-queue-reader:queue")

module.exports =
  class Queue

    constructor: ({accountKey, accountName, @queueName}) ->
      @client = @_buildClient accountName, accountKey

    initialize: -> @create()

    create: -> @client.createQueueAsync @queueName

    messages: (opts = {}) ->
      @client.getMessagesAsync @queueName, opts
      .tap (messages) -> debug "Received Messages: %o", _.map(messages, 'messageText')

    update: (timeout, {messageId, popReceipt, messageText}) ->
      debug "Updating [timeout: #{timeout}, messageId: #{messageId}, popReceipt: #{popReceipt}, messageText: #{JSON.stringify messageText}]"
      @client.updateMessageAsync @queueName, messageId, popReceipt, timeout, messageText
      .tap (message) -> debug "Updated message: %o", message

    remove: ({messageId, popReceipt}) ->
      debug "Removing message: [messageId: #{messageId}, popReceipt: #{popReceipt}]"
      @client.deleteMessageAsync @queueName, messageId, popReceipt
      .tap -> "Removed messageId: #{messageId}"

    push: (message) ->
      @client.putMessageAsync @queueName, message

    _buildClient: (accountName, accountKey) ->
      client = AzureQueueNode.createClient
        accountUrl: "http://#{accountName}.queue.core.windows.net/"
        accountName: accountName
        accountKey: accountKey
        base64: true
      Promise.promisifyAll client
