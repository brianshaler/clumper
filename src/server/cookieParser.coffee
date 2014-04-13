_ = require 'lodash'
nameResolver = require './nameResolver'

module.exports = (files, requestedNames, rawCookie, newestFile = 0) ->
  clientOldest = /\bclumperOldest=([\d]+)/.exec rawCookie
  if !clientOldest
    # don't filter if client doesn't have any files
    return files
  clientOldest = parseInt clientOldest[1]
  if clientOldest > 0 and clientOldest < newestFile
    # don't filter if client has any out-dated files
    return files
  
  cookieMatch = /\bclumper=([^;]+)/.exec rawCookie
  if cookieMatch?[1]?.length >= 8
    cookie = cookieMatch[1]
    clientManifest = {}
    while cookie.length >= 8
      clientManifest[cookie.substring 0, 4] = cookie.substring 4, 8
      cookie = cookie.substring 8
    
    files = _.filter files, (file) ->
      # definitely send it if the client asked for it
      if (_.find requestedNames, (name) -> name == file.name)
        return true
      name = nameResolver file.name
      name = name.replace /^[\/\.]+/, ''
      #console.log "> check to see if #{name}@#{file.version} is in cookie", JSON.stringify clientManifest
      if clientManifest[file.fileId] == file.version
        return false
      true
  files
