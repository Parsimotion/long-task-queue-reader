_ = require "lodash"
winston = require "winston"
Promise = require "bluebird"
{ EventEmitter } = require "events"
convert = require "convert-units"
KeepAliveMessage = require "./keepAliveMessage"
MaxRetriesExceededException = require "./maxRetriesExceededException"

eventsToLog = (logger) ->
  "job-get-messages": -> logger.info "Obteniendo mensajes nuevas"
  "job-finish-messages": -> logger.info "Finalizo la ejecucion de mensajes"
  "message-start": (message) -> logger.info "Iniciando el proceso de un mensaje", message
  "message-finish": (message) -> logger.info "Finalizo la ejecucion de un proceso", message
  "message-touch": ({ messageId, MessageId, messageText, Body }) -> logger.info "Touching #{messageId or MessageId}", messageText or Body
  "job_error": ({ method, message, err }) -> logger.error "An error has ocurred in #{method}(#{ message?.messageId or message?.MessageId })", err

module.exports =
  class LongTaskQueueReader extends EventEmitter

    constructor: (@queue, { @waitingTime = 60, @visibilityTimeout = 60, @maxRetries = 10 }, { level = "info", transports = []}, @MessageExecutor, @runner, @fromPoison) ->
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
      @emit "job-get-messages"

      @queue.messages {
        maxMessages: 1,
        visibilityTimeout: @visibilityTimeout
      }
      .get 0
      .tap (message) => @_execute(message) if message?
      .tap => @emit "job-finish-messages"
      .catch (err) => @emit "job_error", { method: "_executePendingSynchronization", err }

    _nextTimeout: (message) =>
      if _.isEmpty message then convert(@waitingTime).from("s").to("ms") else 0
      
    _buildExecutor: (message) => new @MessageExecutor { @runner, message, @maxRetries, @fromPoison }

    _execute: (message) =>
      keepAliveMessage = @_createKeepAlive message

      @emit "message-start", message
      keepAliveMessage.start()
      @_buildExecutor message
      .execute()
      .tap => @_removeSafety message
      .catch MaxRetriesExceededException, (e) => @_sendToPoison message
      .catch (err) => @emit "job_error", { method: "_execute", err, message }
      .tap -> keepAliveMessage.destroy()
      .then => @emit "message-finish", message

    _sendToPoison: (message) =>
      @queue.sendToPoison message
      .then => @_removeSafety message

    _createKeepAlive: (message) =>
      new KeepAliveMessage message, @visibilityTimeout, @_touch

    _removeSafety: (message) =>
      @queue.remove message
      .catch (err) => @emit "job_error", { method: "_removeSafety", message, err }

    _touch: (message) =>
      @emit "message-touch", message
      @queue.update @visibilityTimeout, message
      .tap (response) -> _.assign message, popReceipt: response.popReceipt
      .catch (err) => @emit "job_error", { method: "_touch", message, err }
