global._ = require 'lodash'
express = require 'express'
path = require 'path'
clumper = require '../'
client = require '../src/client'

clumper.config.defaultCache = clumper.config.cache
clumper.config.noCache =
  read: (name, next) -> next()
  write: (name, data, next) -> next()

global.localStorage = localStorage =
  data: {}
  clear: -> localStorage.data = {}
  getItem: (key) -> localStorage.data[key]
  setItem: (key, value) -> localStorage.data[key] = value
  removeItem: (key) -> delete localStorage.data[key]

global.document = document =
  cookie: ''


# give each test an unused port
beforeEach (done) ->
  @fixtures = path.join __dirname, './fixtures'
  @app = express()
  @app.use clumper.middleware @fixtures
  
  clumper.config.cache = clumper.config.defaultCache
  @client = require '../src/client'
  @client.reset()
  for k, dep of @client.deps
    delete @client.deps[k]
  document.cookie = ''
  
  done()

