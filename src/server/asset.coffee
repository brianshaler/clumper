_ = require 'lodash'
fs = require 'fs'
path = require 'path'
config = require './config'
depcheck = require './depcheck'
crypto = require 'crypto'

resolveName = (name, baseDir = config.baseDir) ->
  name = config.pathFilter name
  if name.charAt(0) != '/'
    name = "/#{name}"
  
  # add .js to everything because why not..
  unless /\.js$/.test name
    name = "#{name}.js"
  
  # make sure relative path is *within* base directory
  fullPath = path.resolve "#{baseDir}#{name}"
  unless baseDir == fullPath.substring 0, baseDir.length
    # invalid path!
    name = name.replace '..', '.'
    fullPath = path.resolve "#{baseDir}#{name}"
  
  # return relative path
  fullPath.substring baseDir.length

load = (name, next) ->
  config.cache.read name, (err, data) ->
    return next err, data if err or data
    
    relativePath = resolveName name
    fullPath = "#{config.baseDir}#{relativePath}"
    file =
      name: name
      path: relativePath
      data: null
      error: null
      dateModified: new Date 0
      version: null
      dependencies: []
    
    fs.readFile fullPath, 'utf-8', (err, content) ->
      file.error = err.code if err
      file.data = content if content
      
      # get date modified
      fs.stat fullPath, (err, stats) ->
        file.dateModified = stats.mtime if !err and stats?.mtime
        t = file.dateModified.getTime()
        config.newestFile = t if t > config.newestFile
        
        hash = crypto.createHash 'md5'
        #hash.update file.name + file.dateModified.getTime()
        hash.update file.path + file.data
        file.version = hash.digest('base64').substring 0, 4
        
        if file.data?.length > 0 and /define\(/.test file.data
          file.dependencies = depcheck file.data, []
          
          # clean up paths
          file.dependencies = _.map file.dependencies, (name) -> config.pathFilter name
          
          # save file data and dependency tree to cache
          config.cache.write name, file, (err) ->
            next null, file
        else
          config.cache.write name, file, (err) ->
            next null, file

module.exports =
  load: load
  resolveName: resolveName