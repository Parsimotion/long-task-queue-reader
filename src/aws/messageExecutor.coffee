AbstractMessageExecutor = require("../abstractMessageExecutor")

module.exports =
  class AwsMessageExecutor extends AbstractMessageExecutor
    _body_: () => @message.Body
    _receiveCount_: () => parseInt(@message.Attributes.ApproximateReceiveCount)
    _messageId_: () => @message.MessageId
    
