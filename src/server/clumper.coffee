config = require './config'
middleware = require './middleware'
assetLoader = require './assetloader'
asset = require './asset'
clumperCache = require './cache'

module.exports =
  middleware: middleware
  config: config
  basicCache: clumperCache
  assetLoader: assetLoader
  asset: asset
