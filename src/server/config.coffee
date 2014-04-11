_ = require 'lodash'
path = require 'path'

cache = {}

config =
  baseDir: "#{path.resolve __dirname, '..'}/public"
  newestFile: 0
  
  # placeholder / pass-through
  pathFilter: (path) ->
    path
  
  # placeholder / pass-through
  cache:
    read: (name, next) ->
      next()
    write: (name, data, next) ->
      next()
  
  configure: (options) ->
    _.extend config, options

module.exports = config
