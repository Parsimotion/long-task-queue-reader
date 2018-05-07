_ = require "lodash"
AzureQueueNode = require "azure-queue-node"
Promise = require "bluebird"

debug = require("debug")("long-task-queue-reader:queue")

module.exports =
  class Queue

    constructor: ({accountKey, accountName, @queueName}) ->
      @client = @_buildClient accountName, accountKey

    initialize: => Promise.map [ @queueName, @_poisonQueueName() ], @create

    create: (queue) => @client.createQueueAsync queue

    sendToPoison: (message) ->  
      @pushPoison message.messageText

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
      .tap -> debug "Removed messageId: #{messageId}"

    push: (message) -> @_push message, @queueName
    
    pushPoison: (message) -> @_push message, @_poisonQueueName()

    _poisonQueueName: -> "#{@queueName}-poison"

    _push: (message, queueName) ->
      @client.putMessageAsync @queueName, message

    _buildClient: (accountName, accountKey) ->
      client = AzureQueueNode.createClient
        accountUrl: "http://#{accountName}.queue.core.windows.net/"
        accountName: accountName
        accountKey: accountKey
        base64: true
      Promise.promisifyAll client
