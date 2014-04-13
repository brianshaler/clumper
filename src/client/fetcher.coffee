cache = require './cache'
Dependency = require './dependency'

queue = []

fetcher =
  listeners: {}
  on: (eventName, listener) ->
    unless fetcher.listeners[eventName]?.length > 0
      fetcher.listeners[eventName] = []
    fetcher.listeners[eventName].push listener
  emit: (eventName, args...) ->
    if fetcher.listeners[eventName]?.length > 0
      for listener in fetcher.listeners[eventName]
        listener.apply null, args
  fetched: []
  fetch: (name, callback) ->
    queue.push
      name: name
      callback: callback
    fetch()

limit = 50
fetch = _.debounce ->
  
  # Filter out any modules that might have snuck into localStorage
  # since they were queued up
  
  queue = _.filter queue, (item) ->
    !(cache.get Dependency.getName item.name)
  
  return unless queue.length > 0
  
  names = _.map queue, (item) -> item.name
  callbacks = _.map queue, (item) -> item.callback
  
  url = "/clumper.json?files=#{names.join ','}"
  
  newest = cache.get 'clumperNewest'
  if newest
    url += "&newest=#{newest}"
  
  currentItems = queue
  queue = []
  
  r = new XMLHttpRequest()
  r.open "GET", url, true
  r.onreadystatechange = ->
    return if r.readyState != 4 or r.status != 200
    data = JSON.parse r.responseText
    return console.log 'NO files?' unless data?.files?
    for file in data.files
      if typeof file.dateModified == 'string'
        file.dateModified = (new Date file.dateModified).getTime()
      #console.log 'fetch found a wild', file.name
      for item in currentItems
        if item.name == file.name
          item.callback null, file
      fetcher.emit 'file', file
    if data.newest > 0
      fetcher.emit 'newest', data.newest
  r.send()
, limit

module.exports = fetcher
