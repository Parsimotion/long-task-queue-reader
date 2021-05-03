AbstractMessageExecutor = require("../abstractMessageExecutor")

module.exports =
  class AzureMessageExecutor extends AbstractMessageExecutor
    _body_: () => @message.messageText 
    _receiveCount_: () => @message.dequeueCount
    _messageId_: () => @message.messageId
    
