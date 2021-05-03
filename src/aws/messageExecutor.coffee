_ = require "lodash"
AbstractMessageExecutor = require("../abstractMessageExecutor")

module.exports =
  class AwsMessageExecutor extends AbstractMessageExecutor
    _body_: () => _.assign {},  @message.Body, @message.MessageId
    _receiveCount_: () => parseInt(@message.Attributes.ApproximateReceiveCount)
    
