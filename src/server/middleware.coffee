_ = require 'lodash'
async = require 'async'
parseurl = require 'parseurl'
config = require './config'
assetLoader = require './assetloader'
asset = require './asset'
formatJS = require './formatjs'
nameResolver = require './nameResolver'

getLatestModified = (files) ->
  latest = -1
  for file in files
    if file.dateModified?.getTime
      t = file.dateModified.getTime()
      latest = t if latest == -1 or t > latest
  if latest == -1
    latest = Date.now()
  latest

processCookie = (files, requestedNames, rawCookie) ->
  clientOldest = /\bclumperOldest=([\d]+)/.exec rawCookie
  if !clientOldest
    # don't filter if client doesn't have any files
    return files
  clientOldest = parseInt clientOldest[1]
  if clientOldest > 0 and clientOldest < config.newestFile
    # don't filter if client has any out-dated files
    return files
  
  len1 = files.length
  clumperCookie = /\bclumper=([^}]+})/.exec rawCookie
  if clumperCookie?[1]
    clientManifest = JSON.parse clumperCookie[1]
    files = _.filter files, (file) ->
      # definitely send it if the client asked for it
      if (_.find requestedNames, (name) -> name == file.name)
        return true
      name = nameResolver file.name
      name = name.replace /^[\/\.]+/, ''
      #console.log "> check to see if #{name}@#{file.version} is in clumperCookie", JSON.stringify clientManifest
      if clientManifest[name] == file.version
        return false
      true
  files

request = (root, options) ->
  throw new TypeError 'root path required' unless root
  
  config.baseDir = root
  config.configure options if options?
  
  (req, res, next) ->
    {pathname} = parseurl req
    formatMatches = pathname.match /\/clumper\.(js|json)$/
    return next() unless formatMatches?[1]
    format = formatMatches[1]
    
    #return next() unless req.query.files?.length > 0
    fileList = req.query.files ? ''
    names = fileList.split ','
    includeClumper = if req.query.include == true or req.query.include == 'true' then true else false
    
    assetLoader names, (err, files) ->
      return next err if err
      
      if format == 'js' and files?.length == 1 and files[0].error
        return res.redirect files[0].name
      
      latest = getLatestModified files
      
      if req.headers['if-modified-since']?
        since = new Date req.headers['if-modified-since']
        if since.getTime() >= latest and since.getTime() >= config.newestFile
          res.writeHead 304
          return res.end()
      
      res.setHeader 'Cache-Control', 'public, max-age=31557600'
      res.setHeader 'Last-Modified', new Date()
      
      if req.headers.cookie
        files = processCookie files, names, req.headers.cookie
      
      if format == 'js'
        res.type 'js'
        formatJS files, includeClumper, (err, text) ->
          return next err if err
          #res.setHeader 'Content-Type', 'text/javascript'
          res.send text
      else
        #res.setHeader 'Content-Type', 'application/json'
        res.type 'json'
        res.send
          files: files
          newest: config.newestFile

module.exports = request