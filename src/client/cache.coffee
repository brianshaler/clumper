
module.exports = cache =

  manifest: {}

  getManifest: ->
    manifestString = cache.get "clumperManifest"
    if manifestString?.length > 0
      cache.manifest = JSON.parse manifestString
    else
      cache.manifest = {}
    cache.updateCookie()
    cache.manifest

  updateManifest: (key, val) ->
    cache.manifest[key] = val
    manifestString = JSON.stringify cache.manifest
    localStorage.setItem "clumperManifest", manifestString
    cache.updateCookie()
    cache.manifest

  updateCookie: ->
    fileIdList = ''
    for name, version of cache.manifest
      str = localStorage.getItem "meta:#{name}"
      if str
        meta = JSON.parse str
        if meta?.fileId?.length == 4 and meta.version.length == 4
          fileIdList += "#{meta.fileId}#{version}"
    document.cookie = [
      "clumper=#{fileIdList}"
      "path=/"
      "expires=Fri, 31 Dec 9999 23:59:59 GMT"
      "clumperOldest=#{cache.getOldestFile()}"
      "path=/"
      "expires=Fri, 31 Dec 9999 23:59:59 GMT"
    ].join '; '

  save: (dep, name, data, error) ->
    version = Date.now()
    dateModified = 0
    fileId = ''
    cachedAt = Date.now()
    if dep
      {name, data, error, fileId, version, dateModified} = dep
      # sent in via tests
      if dep.cachedAt
        cachedAt = dep.cachedAt
    unless !data? or data == 'null'
      localStorage.setItem name, data
    localStorage.setItem "meta:#{name}", JSON.stringify
      name: name
      fileId: fileId
      cachedAt: cachedAt
      dateModified: dateModified
      version: version
      error: error
    newest = localStorage.getItem 'clumperNewest'
    if dateModified > newest
      localStorage.setItem 'clumperNewest', dateModified

    cache.updateManifest name, version

  set: (key, val) ->
    localStorage.setItem key, val

  get: (key) ->
    localStorage.getItem key

  getFirst: (keys) ->
    for key in keys
      item = localStorage.getItem key
      return item if item
    null

  removeItemsOlderThan: (time) ->
    manifest = cache.getManifest()
    for name of manifest
      meta = cache.get "meta:#{name}"
      if meta
        {cachedAt} = JSON.parse meta
        if cachedAt < time
          localStorage.removeItem name
          localStorage.removeItem "meta:#{name}"
          delete manifest[name]
    newest = localStorage.getItem 'clumperNewest'
    if time > newest
      localStorage.setItem 'clumperNewest', time

  getOldestTime: ->
    oldest = 0
    for name of cache.manifest
      meta = cache.get "meta:#{name}"
      if meta
        {cachedAt} = JSON.parse meta
        oldest = cachedAt if cachedAt < oldest or oldest == 0
    oldest

  clear: ->
    localStorage.clear()
    document.cookie = "clumper=; max-age=0"
    document.cookie = "clumperOldest=; max-age=0"
    null
