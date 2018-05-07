_ = require "lodash"
winston = require "winston"
Promise = require "bluebird"
{ EventEmitter } = require "events"
convert = require "convert-units"
KeepAliveMessage = require "./keepAliveMessage"

eventsToLog = (logger) ->
  "job_get_messages": -> logger.info "Obteniendo sincronizaciones nuevas"
  "job_finish_messages": -> logger.info "Finalizo la ejecucion de sincronizaciones"
  "synchronization_start": (message) -> logger.info "Iniciando la sincronizacion", message
  "synchronization_finish": (message) -> logger.info "Finalizo la sincronizacion", message
  "synchronization_touch": ({messageId, messageText}) -> logger.info "Touching #{messageId}", messageText
  "job_error": ({method, err}) -> logger.error "An error has ocurred in #{method}", err

module.exports =
  class LongTaskQueueReader extends EventEmitter

    constructor: (@queue, { @waitingTime = 60, @visibilityTimeout = 60, @maxRetries = 10 }, { level = "info", transports = []}, @MessageExecutor, @runner) ->
      logger = new winston.Logger { level, transports }
      for eventName, action of eventsToLog logger
        @on "#{eventName}", action

    start: => @_initNewTask()

    _initNewTask: =>
      @_executePendingSynchronization()
      .then (message) =>
        setTimeout @_initNewTask, (@_nextTimeout message)
        return

    _executePendingSynchronization: =>
      @emit "job_get_messages"

      @queue.messages {
        maxMessages: 1,
        visibilityTimeout: @visibilityTimeout
      }
      .get 0
      .tap (message) => @_executeIfShould(message)
      .tap => @emit "job_finish_messages"
      .catch (err) => @emit "job_error", { method: "_executePendingSynchronization", err }
    
    _executeIfShould: (message) =>
      shouldExecute = message? and @_buildExecutor(message).shouldExecute()
      @_execute(message) if shouldExecute
    
    _nextTimeout: (message) =>
      if _.isEmpty message then convert(@waitingTime).from("s").to("ms") else 0
      
    _buildExecutor: (message) => new @MessageExecutor { @runner, message, @maxRetries }
    
    _execute: (message) =>
      keepAliveMessage = @_createKeepAlive message

      @emit "synchronization_start", message
      keepAliveMessage.start()
      @_buildExecutor message
      .execute()
      .tap => @_removeSafety message
      .catch (err) => @emit "job_error", { method: "_execute", err }
      .tap -> keepAliveMessage.destroy()
      .then => @emit "synchronization_finish", message

    _createKeepAlive: (message) =>
      new KeepAliveMessage message, @visibilityTimeout, @_touch

    _removeSafety: (message) =>
      @queue.remove message
      .catch (err) => @emit "job_error", { method: "_removeSafety", err }

    _touch: (message) =>
      @emit "synchronization_touch", message
      @queue.update @visibilityTimeout, message
      .tap (response) -> _.assign message, popReceipt: response.popReceipt
      .catch (err) => @emit "job_error", { method: "_touch", err }
