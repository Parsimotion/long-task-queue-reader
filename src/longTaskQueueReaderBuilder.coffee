winston = require "winston"
Promise = require "bluebird"
QueueProcessor = require "./longTaskQueueReader"

module.exports =
  class LongTaskQueueReaderBuilder

    constructor: ->
      @transports = [
        new winston.transports.Console timestamp: true
      ]
      @dependencies = []
      @implementation = "azure"

    withLogger: (opts) ->
      Logger = @_internalRequire "logger"
      logger = new Logger opts
      @transports.push logger.transport()
      @dependencies.push logger
      @

    withQueue: (opts) ->
      { @waitingTime, @timeToUpdateMessage } = opts
      Queue = @_internalRequire "queue"
      @queue = new Queue opts
      @dependencies.push @queue
      @

    withRunner: (@runner) -> @
    
    withMaxRetries: (@maxRetries) -> @

    build: ->
      Promise.map @dependencies, (dependency) -> dependency.initialize()
      .then => new QueueProcessor @queue, { @waitingTime, @timeToUpdateMessage, @maxRetries }, { @transports }, @_internalRequire("messageExecutor"), @runner

    _internalRequire: (name) -> require "./#{@implementation}/#{name}"