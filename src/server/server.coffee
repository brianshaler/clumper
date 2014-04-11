path = require 'path'
express = require 'express'
clumper = require './clumper'

rootDir = path.resolve __dirname, '..'

app = express()

app.use app.router
app.use express.static "#{rootDir}/public"

app.use clumper.middleware "#{rootDir}/public"

app.get '/', (req, res, next) ->
  res.redirect '/demo.html'

app.listen 3000
