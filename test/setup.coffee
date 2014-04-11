express = require 'express'
path = require 'path'
clumper = require '../'

# give each test an unused port
beforeEach (done) ->
  @fixtures = path.join __dirname, './fixtures'
  @app = express()
  @app.use clumper.middleware @fixtures
  done()

