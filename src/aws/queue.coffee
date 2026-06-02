_ = require "lodash"
{ SQSClient, CreateQueueCommand, SendMessageCommand, ReceiveMessageCommand, DeleteMessageCommand, ChangeMessageVisibilityCommand, GetQueueUrlCommand } = require "@aws-sdk/client-sqs"
Promise = require "bluebird"
retry = require "bluebird-retry"

debug = require("debug")("long-task-queue-reader:queue")
tryParse = (it) -> try JSON.parse(it)
queueConfigDefaults = {
  VisibilityTimeout: "240" # seconds
  MessageRetentionPeriod: "28800" # seconds (8 hrs)
}

module.exports =
  class Queue

    constructor: (options) ->
      @queueName = options.queueName or options.name
      @client = @_buildClient options
      @attributes = _.defaults options.config, queueConfigDefaults

    initialize: =>
      Promise.map [ @queueName, @_poisonQueueName() ], @create
      .then(@_setQueueUrl)

    _setQueueUrl: () =>
      @_queueUrl @queueName
        .then (data) => @queueUrl = data.QueueUrl

    create: (queueName) =>
      Promise.resolve(@client.send new CreateQueueCommand { QueueName: queueName, Attributes: @attributes })
      .catch (e) => throw e unless e.name is "QueueAlreadyExists"

    sendToPoison: (message) ->
      @pushPoison message.Body

    messages: (opts = {}) ->
      Promise.resolve(@client.send new ReceiveMessageCommand {
        AttributeNames: [ "All" ],
        MaxNumberOfMessages: opts.maxMessages or 1,
        MessageAttributeNames: [ ],
        QueueUrl: @queueUrl,
        VisibilityTimeout: opts.visibilityTimeout or 120,
        WaitTimeSeconds: opts.waitingTime or 0
      })
      .then (data) ->
        return [] unless data.Messages
        debug "Received Messages: %o", _.map(data.Messages, 'Body')
        data.Messages.map (it) => _.update(it, "Body", tryParse)

    update: (timeout, { MessageId, ReceiptHandle, Body }) ->
      debug "Updating [timeout: #{timeout}, messageId: #{MessageId}, popReceipt: #{ReceiptHandle}, messageText: #{JSON.stringify Body}]"
      Promise.resolve(@client.send new ChangeMessageVisibilityCommand {
        ReceiptHandle,
        QueueUrl: @queueUrl,
        VisibilityTimeout: timeout
      })
      .tap (message) -> debug "Updated message: %o", message

    remove: ({ MessageId, ReceiptHandle }) ->
      debug "Removing message: [messageId: #{MessageId}, popReceipt: #{ReceiptHandle}]"
      retry () => @client.send new DeleteMessageCommand { QueueUrl: @queueUrl, ReceiptHandle }
      .tap -> debug "Removed messageId: #{MessageId}"

    push: (message) -> @_push @queueUrl, message

    pushPoison: (message) -> @_push @_poisonQueueUrl(), message

    _push: (queueUrl, message) =>
      @client.send new SendMessageCommand {
        DelaySeconds: 0,
        MessageAttributes: {},
        MessageBody: JSON.stringify(message),
        QueueUrl: queueUrl
      }

    _poisonQueueUrl: -> @_toPoison @queueUrl

    _poisonQueueName: -> @_toPoison @queueName

    _toPoison: (it) -> "#{it}-poison"

    _queueUrl: (queueName) ->
      Promise.resolve(@client.send new GetQueueUrlCommand { QueueName: queueName })

    _buildClient: ({ access, secret, region = "us-east-1" }) ->
      new SQSClient {
        credentials: {
          accessKeyId: access,
          secretAccessKey: secret
        },
        region
      }
