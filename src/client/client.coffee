# requires (via gulp-concat) lodash, and requirejs

queue = []
deps = {}
manifest = {}

window.clumper = clumper =
  path: "/scripts.json"
  
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
    stored = getItem name
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
    setItem dep
  
  eval: (name) ->
    #console.log 'eval', name
    stored = getItem name
    #require [name]
    if stored
      ((define) ->
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
    
    
    newest = localStorage.getItem 'clumperNewest'
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
            setItem dep
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
          setItem dep
      if data.newest > 0
        if manifest
          removeItemsOlderThan data.newest
    r.send()

fetch = _.debounce clumper.fetch, 50

getNames = (name) ->
  name = name.replace /^[\/\.]+/, ''
  unless /\.js$/.test name
    name = "#{name}.js"
  names = [
    name
    "/#{name}"
    "./#{name}"
    "/./#{name}"
  ]

getName = (name) ->
  getNames(name)[0]

getItem = (name) ->
  names = getNames name
  for _name in names
    stored = localStorage.getItem _name
    if stored
      return stored
  null

setItem = (dep, name, data, error) ->
  version = Date.now()
  dateModified = 0
  if dep
    {name, data, error, version, dateModified} = dep
  names = getNames name
  name = names[0]
  unless !data? or data == 'null'
    localStorage.setItem name, data
  localStorage.setItem "meta:#{name}", JSON.stringify
    name: name
    cachedAt: Date.now()
    dateModified: dateModified
    version: version
    error: error
  newest = localStorage.getItem 'clumperNewest'
  if dateModified > newest
    localStorage.setItem 'clumperNewest', dateModified
  
  manifestString = localStorage.getItem "clumperManifest"
  if manifestString?.length > 0
    manifest = JSON.parse manifestString
  else
    manifest = {}
  manifest[name] = version
  manifestString = JSON.stringify manifest
  localStorage.setItem "clumperManifest", manifestString
  document.cookie = "clumper=#{manifestString}"
  document.cookie = "clumperOldest=#{getOldestFile()}"

removeItemsOlderThan = (time) ->
  localStorage.setItem 'clumperNewest', time
  manifestString = localStorage.getItem "clumperManifest"
  if manifestString?.length > 0
    manifest = JSON.parse manifestString
  else
    manifest = {}
  for name of manifest
    meta = localStorage.getItem "meta:#{name}"
    if meta
      {cachedAt} = JSON.parse meta
      if cachedAt < time
        localStorage.removeItem name
        delete manifest[name]
clumper.removeItemsOlderThan = removeItemsOlderThan

getNewestFile = ->
  newest = 0
  for name of manifest
    meta = localStorage.getItem "meta:#{name}"
    if meta
      {dateModified} = JSON.parse meta
      newest = dateModified if dateModified > newest
  newest

getOldestFile = ->
  oldest = -1
  for name of manifest
    meta = localStorage.getItem "meta:#{name}"
    if meta
      {cachedAt} = JSON.parse meta
      oldest = cachedAt if cachedAt < oldest or oldest == -1
  oldest

getDep = (name, autoCreate = true) ->
  names = getNames name
  for _name in names
    if deps[_name]
      return deps[_name]
  if autoCreate
    deps[name] = new Dependency name
  else
    null


class Dependency
  constructor: (@name) ->
    @processed = false
    @listeners = []
    
    @error = null
    @data = null
    @version = '___'
    @dateModified = 0
  
  onProcess: (callback) =>
    return unless callback
    if @processed
      callback @error, @data
    else
      @listeners.push callback
  
  process: (@data) =>
    @processed = true
    for listener in @listeners
      listener @error, @
    @listeners = []
  
  fail: (@error) =>
    @processed = true
    for listener in @listeners
      listener @error
    @listeners = []


# hack requirejs to load modules through clumper
@require.load = (context, moduleName, url) ->
  clumper.require url, (err, dep) ->
    if !dep? or dep?.error
      # fall back to letting requirejs do it's own thang
      xhr = new XMLHttpRequest()
      xhr.open 'GET', url, true
      xhr.send()
      xhr.onreadystatechange = ->
        if xhr.readyState == 4
          eval xhr.responseText
          name = getName url
          setItem null, name, xhr.responseText
          context.completeLoad moduleName
    else
      eval dep.data
      context.completeLoad moduleName
