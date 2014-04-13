_ = require 'lodash'
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
Promise = require 'bluebird'

config = require './config'
depcheck = require './depcheck'
nameResolver = require './nameResolver'

hashFile = (name, next) ->
  load name, (err, file) ->
    return next err if err
    next null, hashFilePathAndData file.path, file.data

hashFilePath = (path) ->
  hash = crypto.createHash 'md5'
  hash.update path
  hash.digest('base64').substring 0, 4

hashFilePathAndData = (path, data) ->
  hash = crypto.createHash 'md5'
  # Not a good idea to use mtime if starting your service rebuilds files
  # hash.update path + dateModified.getTime()
  hash.update path + data
  hash.digest('base64').substring 0, 4


class File
  constructor: (name) ->
    @relativePath = nameResolver name
    @fullPath = path.join config.baseDir, @relativePath
    @properties =
      name: name
      path: @relativePath
      data: null
      error: null
      dateModified: new Date 0
      version: null
      dependencies: []
  
  loadFile: =>
    new Promise (resolve, reject) =>
      fs.readFile @fullPath, 'utf-8', (err, content) =>
        return reject() if err and !err.code
        @properties.error = err.code if err
        @properties.data = content if content
        resolve()
  
  getDateModified: =>
    new Promise (resolve, reject) =>
      fs.stat @fullPath, (err, stats) =>
        @properties.dateModified = stats.mtime if !err and stats?.mtime
        resolve()
  
  getVersion: =>
    @properties.version = hashFilePathAndData @properties.path, @properties.data
    @
  
  getFileId: =>
    @properties.fileId = hashFilePath @properties.path
    @
  
  getDependencies: =>
    if @properties.data?.length > 0 and /define\(/.test @properties.data
      @properties.dependencies = depcheck @properties.data, []
      # clean up paths
      @properties.dependencies = _.uniq _.map @properties.dependencies, (name) -> nameResolver name
    @

load = (name, next) ->
  r = Math.random()
  file = new File name
  Promise.all [file.loadFile(), file.getDateModified()]
  .catch (err) ->
    console.log err.stack
    console.log 'done! (catch)', r
    next err
  .error (err) ->
    console.log 'done! (error)', r
    next err
  .done ->
    file.getVersion()
    file.getFileId()
    file.getDependencies()
    t = file.properties.dateModified.getTime()
    config.newestFile = t if t > config.newestFile
    next null, file.properties
  return
  
  fs.readFile fullPath, 'utf-8', (err, content) ->
    file.error = err.code if err
    file.data = content if content
    
    # get date modified
    fs.stat fullPath, (err, stats) ->
      file.dateModified = stats.mtime if !err and stats?.mtime
      
      t = file.dateModified.getTime()
      config.newestFile = t if t > config.newestFile
      
      file.version = hashFilePathAndData file.path, file.data
      
      if file.data?.length > 0 and /define\(/.test file.data
        file.dependencies = depcheck file.data, []
        # clean up paths
        file.dependencies = _.uniq _.map file.dependencies, (name) -> nameResolver name
      
      next null, file

module.exports =
  load: load
  hashFile: hashFile
  hashFilePathAndData: hashFilePathAndData
