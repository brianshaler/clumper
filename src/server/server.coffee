path = require 'path'
express = require 'express'
clumper = require './clumper'

rootDir = path.resolve __dirname, '..'

clumper.config.configure
  baseDir: "#{rootDir}/public"

app = express()

app.use app.router
app.use express.static "#{rootDir}/public"

app.get '/scripts.:format?', clumper.request

app.get '/', (req, res, next) ->
  res.redirect '/demo.html'

app.listen 3000
