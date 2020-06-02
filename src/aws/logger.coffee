winston = require "winston"
Promise = require "bluebird"
WinstonCloudWatch = require "winston-cloudwatch"
debug = require("debug")("long-task-queue-reader:logger")

require "winston-azure-blob-transport"

module.exports =
  class AwsLogger

    constructor: ({ access, secret, region, logGroupName, logStreamName, level = "info" }) ->
      @_transport = new WinstonCloudWatch {
          logGroupName,
          logStreamName,
          awsAccessKeyId: access,
          awsSecretKey: secret,
          level,
          awsRegion: region or 'us-east-1'
        }

    initialize: -> @_transport.initialize?()

    transport: -> @_transport