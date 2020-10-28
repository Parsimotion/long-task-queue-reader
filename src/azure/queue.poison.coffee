Promise = require "bluebird";
Queue = require "./queue";

module.exports = 
  class QueuePoison extends Queue 
    constructor: (opts) ->
      super opts
      @queueName = @_poisonQueueName @queueName

    pushPoison: () -> Promise.resolve()

    initialize: => @create @queueName