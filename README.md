# long-task-queue-reader

[![NPM version](https://badge.fury.io/js/long-task-queue-reader.png)](http://badge.fury.io/js/long-task-queue-reader)

Long task Queue reader



```CoffeeScript

queueConfig = {
  accountName: "ACCOUNT_NAME"
  accountKey: "ACCOUNT_KEY"
  queueName: "QUEUE_NAME"
  waitingTime: 10  # time to sleep when queue is empty (sec)
  visibilityTimeout: #time to
}

loggerConfig = {
  accountName: "ACCOUNT_NAME"
  accountKey: "ACCOUNT_KEY"
  container: "CONTAINER_NAME"
  name: "LOG_NAME"
  level: "LOG_LEVEL"
}

new LongTaskQueueBuilder()
  .withLogger loggerConfig
  .withQueue queueConfig
  .withRunner (message) -> new SynchronizationRunner(message).run()
  .withMaxRetries(10)
  .build()
  .then (queueReader) -> queueReader.start()

```
