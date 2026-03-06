winston = require "winston"
Promise = require "bluebird"
QueueProcessor = require "./longTaskQueueReader"
executionModes =
  continuous: require "./executionModes/continuousExecutionMode"
  once: require "./executionModes/onceExecutionMode"

module.exports =
  class LongTaskQueueReaderBuilder

    constructor: (@implementation = "azure", @poison = false) ->
      @transports = [
        new winston.transports.Console timestamp: true
      ]
      @dependencies = []

    withLogger: (opts) ->
      Logger = @_internalRequire "logger"
      logger = new Logger opts
      @transports.push logger.transport()
      @dependencies.push logger
      @
    
    withQueue: (opts) ->
      { @waitingTime, @timeToUpdateMessage } = opts
      Queue = @_internalRequire("queue#{ if @poison then ".poison" else "" }")
      @queue = new Queue opts
      @dependencies.push @queue
      @

    fromPoison: (@poison) -> @

    withRunner: (@runner) -> @
    
    withMaxRetries: (@maxRetries) -> @
    
    withExecutionMode: (mode) ->
      ExecutionMode = executionModes[mode] or executionModes.continuous
      @executionMode = new ExecutionMode()
      @
    
    withImplementation: (@implementation) -> @

    build: ->
      Promise.map @dependencies, (dependency) -> dependency.initialize()
      .then => new QueueProcessor @queue, { @waitingTime, @timeToUpdateMessage, @maxRetries }, { @transports }, @_internalRequire("messageExecutor"), @runner, @poison, @executionMode

    _internalRequire: (name) -> require "./#{@implementation}/#{name}"