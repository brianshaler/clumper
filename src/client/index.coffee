# requires (via gulp-concat) lodash, and requirejs
#console.log 'setting up clumper', window.require, require

Dependency = require './dependency'
cache = require './cache'
fetcher = require './fetcher'

queue = []
deps = {}

clumper =
  
  url:
    path: '/clumper'
    extension:
      js: '.js'
      json: '.json'
    listName: 'files'
    separator: ','
    format: (names, format = 'json') ->
      names = [] unless names?.length > 0
      {path, listName, extension, separator} = clumper.url
      "#{path}#{extension[format]}?#{listName}=#{names.join separator}"
  
  require: (name, next) ->
    
    # test to see if it exists
    dep = getDep name, false # don't autoCreate
    if dep?
      if dep.processed
        next null, dep if next
      else
        dep.onProcess next if next
      return
    
    # doesn't exist, autoCreate
    dep = getDep name
    dep.onProcess next
    
    # check localStorage
    stored = cache.get Dependency.getName name
    if stored
      dep.process stored
    else
      fetcher.fetch dep.name, (err, file) ->
        dep.fileId = file.fileId if file.fileId
        dep.version = file.version if file.version
        dep.dateModified = file.dateModified
        if file.data
          dep.process file.data
        else if file.error
          dep.fail file.error
        else
          console.log file
          throw new Error "No file OR data?!"
        cache.save dep
  
  process: (name, err, data, fileId = '', version = Date.now(), dateModified = 0) ->
    dep = getDep name
    unless dep.processed
      dep.fileId = fileId
      dep.version = version
      dep.dateModified = dateModified
      if data
        dep.process data
      else if err
        dep.fail err
    cache.save dep
  
  eval: (name) ->
    stored = cache.get Dependency.getName name
    #console.log 'eval', name
    #require [name]
    if stored
      ((define, module, exports) ->
        #console.log 'running eval on', name, 'without define()'
        eval stored
      )(->)
  
  reset: ->
    cache.clear()

getDep = (name, autoCreate = true) ->
  name = Dependency.getName name
  return deps[name] if deps[name]
  if autoCreate
    deps[name] = new Dependency name
  else
    null

# When a possibly unknown module shows up
fetcher.on 'file', (file) ->
  dep = getDep file.name, false
  # try finding it via path if we haven't seen that name
  dep = getDep file.path, false if !dep?
  
  # Same version already processed, nothing to do here..
  return if dep?.processed and dep.version == file.version
  
  #console.log "saving unexpected module #{file.name}"
  if dep
    # we should either have a data or error payload for each item
    if file.data
      dep.version = file.version
      dep.dateModified = file.dateModified
      dep.process file.data
    else if file.error
      dep.fail file.error
  else
    # received a module we didn't know about
    dep = getDep file.name
    dep.version = file.version
    dep.dateModified = file.dateModified
    unless dep.processed
      if file.data
        dep.process file.data
      else if file.error
        dep.fail file.error
  cache.save dep

fetcher.on 'newest', (newest) ->
  cache.removeItemsOlderThan newest if newest > 0

clumper.removeItemsOlderThan = cache.removeItemsOlderThan
clumper.getName = Dependency.getName

clumper.saveModule = (name, data, error) ->
  name = Dependency.getName name
  dep = getDep name
  dep.data = data
  dep.error = error
  cache.save dep

# expose for debug purposes only
clumper.deps = deps
clumper.cache = cache

module.exports = clumper
