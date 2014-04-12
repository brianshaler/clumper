# requires (via gulp-concat) lodash, and requirejs
#console.log 'setting up clumper', window.require, require

Dependency = require './dependency'
cache = require './cache'

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
      queue.push dep
      fetch()
  
  process: (name, err, data, version = Date.now(), dateModified = 0) ->
    dep = getDep name
    unless dep.processed
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
  
  fetch: ->
    return unless queue.length > 0
    
    names = _.map queue, (file) ->
      file.name
    
    names = _.filter names, (name) ->
      dep = getDep name, false
      !dep? or (!dep.processed and !dep.error)
    
    return unless names.length > 0
    
    url = "#{clumper.path}?files=#{names.join ','}"
    
    newest = cache.get 'clumperNewest'
    if newest
      url += "&newest=#{newest}"
    
    queue = []
    
    r = new XMLHttpRequest()
    r.open "GET", url, true
    r.onreadystatechange = ->
      return if r.readyState != 4 or r.status != 200
      data = JSON.parse r.responseText
      return console.log 'no files?' unless data?.files?
      for file in data.files
        if typeof file.dateModified == 'string'
          file.dateModified = (new Date file.dateModified).getTime()
        dep = getDep file.name, false
        if !dep?
          # try fetching it via path if we haven't seen that name
          dep = getDep file.path, false
        
        if dep
          # we should either have a data or error payload for each item
          if file.data
            dep.version = file.version
            dep.dateModified = file.dateModified
            dep.process file.data
            cache.save dep
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
      if data.newest > 0
        cache.removeItemsOlderThan data.newest
    r.send()

fetch = _.debounce clumper.fetch, 50

clumper.removeItemsOlderThan = cache.removeItemsOlderThan

getDep = (name, autoCreate = true) ->
  name = Dependency.getName name
  return deps[name] if deps[name]
  if autoCreate
    deps[name] = new Dependency name
  else
    null

clumper.saveModule = (name, data, error) ->
  name = Dependency.getName name
  cache.set dep, name, data, error

# expose for debug purposes only
clumper.deps = deps
clumper.cache = cache

module.exports = clumper
