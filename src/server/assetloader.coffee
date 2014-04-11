_ = require 'lodash'
async = require 'async'
asset = require './asset'

module.exports = (names, next) ->
  requestedNames = names
  allNames = _.clone names
  allFiles = []
  
  loadFiles = (names, _next) ->
    async.map names, asset.load, (err, files) ->
      return _next err if err
      allFiles = allFiles.concat files
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