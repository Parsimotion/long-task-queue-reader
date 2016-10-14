# long-task-queue-reader

[![NPM version](https://badge.fury.io/js/long-task-queue-reader.png)](http://badge.fury.io/js/long-task-queue-reader)

Long task Queue reader



```CoffeeScript

queueConfig = {
  accountName: "ACCOUNT_NAME"
  accountKey: "ACCOUNT_KEY"
  queueName: "QUEUE_NAME"
  waitingTime: 10  # time to sleep when queue is empty (ms)
  visibilityTimeout: #time to
}

loggerConfig = {
  accountName: "ACCOUNT_NAME"
  accountKey: "ACCOUNT_KEY"
  container: logContainer
  level: logLevel
  name: new Date().toString()
}

winston.info "SynchronizationJob-config", { azureConfig, queueConfig }

new LongTaskQueueBuilder()
  .withLogger loggerConfig
  .withQueue queueConfig
  .withRunner (message) -> new SynchronizationRunner(message).run()
  .build()
  .then (queueReader) -> queueReader.start()

```