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
## 📦 Publishing a New Version

Package publishing is now handled automatically via a GitHub Action triggered on `push` to the `main` or `master` branches.

You can also trigger it manually from the **Actions** tab using the `Release` workflow.

The workflow supports prerelease versions (e.g., `alpha`, `beta`) through the `prereleaseTag` input.

> 🔐 The release process uses the contents of the `lib/` directory generated during build.

## ✅ Commit Message Validation

[`commitlint`](https://github.com/conventional-changelog/commitlint) was added to ensure commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard.

Commit messages are automatically validated before each commit using [Husky](https://typicode.github.io/husky/).

**Example of a valid commit message:**

```bash
feat: add login functionality
```
> If the format is invalid, the commit will be blocked.
