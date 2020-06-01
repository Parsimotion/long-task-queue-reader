_ = require "lodash"
AWS = require 'aws-sdk'
Promise = require "bluebird"

debug = require("debug")("long-task-queue-reader:queue")

module.exports =
  class Queue

    constructor: (options) ->
      { @queueUrl } = options
      @client = @_buildClient options

    initialize: => Promise.map [ @queueUrl, @_poisonQueueUrl() ], @create

    create: (queueUrl) => @client.createQueueAsync QueueName: @_queueName queueUrl

    sendToPoison: (message) ->  
      @pushPoison message.messageText

    messages: (opts = {}) ->
      @client.receiveMessageAsync {
        AttributeNames: [ "SentTimestamp" ],
        MaxNumberOfMessages: opts.maxMessages or 1,
        MessageAttributeNames: [ "All" ],
        QueueUrl: @queueUrl,
        VisibilityTimeout: opts.visibilityTimeout or 120,
        WaitTimeSeconds: opts.visibilityTimeout or 0
      }
      .tap ({ Messages }) -> debug "Received Messages: %o", _.map(Messages, 'Body') if Messages

    update: (timeout, { MessageId, ReceiptHandle, Body }) ->
      debug "Updating [timeout: #{timeout}, messageId: #{MessageId}, popReceipt: #{ReceiptHandle}, messageText: #{JSON.stringify Body}]"
      @client.changeVisibilityTimeoutAsync {
        ReceiptHandle,
        QueueUrl: @queueUrl,
        VisibilityTimeout: timeout
      }
      .tap (message) -> debug "Updated message: %o", message

    remove: ({ MessageId, ReceiptHandle }) ->
      debug "Removing message: [messageId: #{MessageId}, popReceipt: #{ReceiptHandle}]"
      @client.deleteMessageAsync { QueueUrl: @queueUrl, ReceiptHandle }
      .tap -> debug "Removed messageId: #{MessageId}"

    push: (message) -> @client.putMessageAsync @queueUrl, message
    
    pushPoison: (message) -> @client.putMessageAsync @_poisonQueueUrl(), message

    _push: (queueUrl, message) =>
      @client.sendMessageAsync {
        DelaySeconds: 0,
        MessageAttributes: {},
        MessageBody: message,
        QueueUrl: @queueUrl
      }

    _poisonQueueUrl: -> "#{@queueUrl}-poison"

    _queueName: (queueUrl) -> _(queueUrl.split("/")).last()

    _buildClient: ({ accessKey, secretKey, region = "us-east-1" }) ->
      AWS.config.update { accessKey, secretKey, region }
      Promise.promisifyAll new AWS.SQS {}

