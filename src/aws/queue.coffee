_ = require "lodash"
AWS = require 'aws-sdk'
Promise = require "bluebird"

debug = require("debug")("long-task-queue-reader:queue")
tryParse = (it) -> try JSON.parse(it)
module.exports =
  class Queue

    constructor: (options) ->
      @queueName = options.name
      @client = @_buildClient options

    initialize: => 
      Promise.map [ @queueName, @_poisonQueueName() ], @create
      .then () => @_queueUrl @queueName
      .get "QueueUrl"
      .then (@queueUrl) =>

    create: (queueName) => @client.createQueueAsync QueueName: queueName

    sendToPoison: (message) ->  
      @pushPoison message.Body

    messages: (opts = {}) ->
      @client.receiveMessageAsync {
        AttributeNames: [ "All" ],
        MaxNumberOfMessages: opts.maxMessages or 1,
        MessageAttributeNames: [ ],
        QueueUrl: @queueUrl,
        VisibilityTimeout: opts.visibilityTimeout or 120,
        WaitTimeSeconds: opts.waitingTime or 0
      }
      .then (data) -> 
        return [] unless data.Messages
        debug "Received Messages: %o", _.map(data.Messages, 'Body')
        data.Messages.map (it) => _.update(it, "Body", tryParse)

    update: (timeout, { MessageId, ReceiptHandle, Body }) ->
      debug "Updating [timeout: #{timeout}, messageId: #{MessageId}, popReceipt: #{ReceiptHandle}, messageText: #{JSON.stringify Body}]"
      @client.changeMessageVisibilityAsync {
        ReceiptHandle,
        QueueUrl: @queueUrl,
        VisibilityTimeout: timeout
      }
      .tap (message) -> debug "Updated message: %o", message

    remove: ({ MessageId, ReceiptHandle }) ->
      debug "Removing message: [messageId: #{MessageId}, popReceipt: #{ReceiptHandle}]"
      @client.deleteMessageAsync { QueueUrl: @queueUrl, ReceiptHandle }
      .tap -> debug "Removed messageId: #{MessageId}"

    push: (message) -> @_push @queueUrl, message
    
    pushPoison: (message) -> @_push @_poisonQueueUrl(), message
    
    _push: (queueUrl, message) =>
      @client.sendMessageAsync {
        DelaySeconds: 0,
        MessageAttributes: {},
        MessageBody: JSON.stringify(message),
        QueueUrl: queueUrl
      }

    _poisonQueueUrl: -> @_toPoison @queueUrl
    
    _poisonQueueName: -> @_toPoison @queueName

    _toPoison: (it) -> "#{it}-poison"
    
    _queueUrl: (queueName) -> 
      @client.getQueueUrlAsync QueueName: queueName

    _buildClient: ({ access, secret, region = "us-east-1" }) ->
      AWS.config.update { accessKey: access, secretKey: secret, region }
      Promise.promisifyAll new AWS.SQS({}), filter: (functionName) -> !_(functionName).endsWith("Async")

