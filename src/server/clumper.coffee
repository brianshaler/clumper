config = require './config'
clumperRequest = require './request'
clumperCache = require './cache'

module.exports =
  config: config
  request: clumperRequest
  basicCache: clumperCache
