# basic in-memory cache example

cache = {}
cacheDuration = 30 * 1000

module.exports =
  
  read: (name, next) ->
    if cache[name]?.time > Date.now() - cacheDuration
      return next null, cache[name].data
    next()
  
  write: (name, data, next) ->
    cache[name] =
      time: Date.now()
      data: data
    next()
