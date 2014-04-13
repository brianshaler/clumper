path = require 'path'
express = require 'express'
clumper = require './clumper'

rootDir = path.resolve __dirname, '../..'

app = express()

app.use app.router
app.use express.static "#{rootDir}/public"

options =
  pathFilter: (path) ->
    path = path.replace /^[\/\.]*foobar\//, './'
    unless path.charAt(0) == '/'
      path = "/#{path}"
    path
  cache: clumper.basicCache

app.use clumper.middleware "#{rootDir}/public", options

app.get '/', (req, res, next) ->
  res.redirect '/demo.html'

app.listen 3000
