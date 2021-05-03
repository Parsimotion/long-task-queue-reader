_ = require "lodash"
AbstractMessageExecutor = require("../abstractMessageExecutor")

module.exports =
  class AzureMessageExecutor extends AbstractMessageExecutor
    _body_: () => _.assign {}, @message.messageText. { messageId: @message.messageId }     
    _receiveCount_: () => @message.dequeueCount
    
