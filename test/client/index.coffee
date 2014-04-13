clumper = require '../../'
Dependency = require '../../src/client/dependency'
nameResolver = require '../../src/server/nameResolver'
fs = require 'fs'
should = require 'should'
path = require 'path'
_url = require 'url'
parseUrl = _url.parse
require 'mocha'

class XMLHttpRequest
  constructor: ->
  open: (@method = "GET", @url) ->
  onreadystatechange: ->
  send: =>
    {pathname, query} = parseUrl @url, true
    
    setTimeout =>
      @readyState = 4
      @status = 200
      if pathname == '/clumper.json'
        files = []
        names = query.files.split ','
        clumper.assetLoader names, (err, files) =>
          @responseText = JSON.stringify files: files
          @onreadystatechange()
      else
        filePath = path.join @fixtures, pathname
        fs.readFile filePath, (err, contents) =>
          @responseText = contents
          @onreadystatechange()
    , 1
global.XMLHttpRequest = XMLHttpRequest

describe 'Client Library', ->
  
  it 'should allow a module to be manually injected', (done) ->
    module = require path.join @fixtures, './a.json'
    {name, error, data, version, dateModified} = module
    
    @client.process name, error, data, version, dateModified
    @client.eval name
    cachedData = @client.cache.get @client.getName name
    
    should.exist cachedData
    cachedData.should.equal module.data
    
    done()

  it 'should load a module via XMLHttpRequest', (done) ->
    moduleName = './a.js'
    module = require path.join @fixtures, './a.json'
    {name, error, data, version, dateModified} = module
    
    XMLHttpRequest::fixtures = @fixtures
    
    clumper.config.cache = clumper.config.noCache
    
    @client.require moduleName, (err, dep) ->
      should.exist dep
      should.exist dep.data
      dep.data.should.equal module.data
      done()

  it 'should respond with ENOENT for missing modules', (done) ->
    moduleName = './404.js'
    module = require path.join @fixtures, './a.json'
    {name, error, data, version, dateModified} = module
    
    XMLHttpRequest::fixtures = @fixtures
    
    clumper.config.cache = clumper.config.noCache
    
    @client.require moduleName, (err, dep) ->
      should.exist dep
      should.exist dep.error
      dep.error.should.equal 'ENOENT'
      done()
