_ = require 'lodash'
async = require 'async'
asset = require './asset'
config = require './config'

module.exports = (names, next) ->
  requestedNames = names
  allNames = _.clone names
  allFiles = []
  
  loadAsset = (name, _next) ->
    cache = config.cache
    
    unless cache?.read and cache.write
      return asset.load name, _next
    
    cache.read name, (err, file) ->
      return _next err, file if err or file
      asset.load name, (err, file) ->
        return _next err if err
        cache.write name, file, (err) ->
          return _next err if err
          _next null, file
  
  loadFiles = (names, _next) ->
    async.map names, loadAsset, (err, files) ->
      return _next err if err
      
      allFiles = allFiles.concat _.filter files, (file) ->
        return true if requestedNames.indexOf(file.name) != -1
        paths = _.pluck allFiles, 'path'
        return false if (_.find paths, (path) -> path.toLowerCase() == file.path.toLowerCase())
        true
      allNames = allNames.concat _.pluck files, 'name'
      
      # gather dependencies from each of the loaded files
      deps = _.uniq _.flatten _.pluck files, 'dependencies'
      # only keep files we haven't seen yet
      deps = _.filter deps, (dep) ->
        !(_.find allNames, (existing) -> existing == dep)
      
      # recurse if we have some new deps
      if deps.length > 0
        loadFiles deps, _next
      else
        # Only respond with errors on modules specifically requested
        allFiles = _.filter allFiles, (file) ->
          return true unless file.error
          if (_.find requestedNames, (name) -> name == file.name)
            true
          else
            false
        # complete
        _next null, allFiles
  
  loadFiles names, next