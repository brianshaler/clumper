clumper = require '../../'
cache = require '../../src/client/cache'
should = require 'should'
path = require 'path'
require 'mocha'

global.localStorage = localStorage =
  data: {}
  clear: -> localStorage.data = {}
  getItem: (key) -> localStorage.data[key]
  setItem: (key, value) -> localStorage.data[key] = value

global.document = document =
  cookie: ''

describe 'client/cache', ->
  
  beforeEach (done) ->
    localStorage.clear()
    done()
  
  it 'save to and read from localStorage synchronously', (done) ->
    key = 'testKey'
    value = 'testValue'
    cache.set key, value
    savedValue = cache.get key
    should.exist savedValue
    savedValue.should.equal value
    done()
  
  it 'should cache and read a module.data', (done) ->
    result = require path.join @fixtures, './a.json'
    result.dateModified = new Date result.dateModified
    cache.save result
    cachedModule = cache.get result.name
    should.exist cachedModule
    cachedModule.should.equal result.data
    done()
  
  it 'should cache and save version to manifest', (done) ->
    result = require path.join @fixtures, './a.json'
    result.dateModified = new Date result.dateModified
    cache.save result
    cachedVersion = cache.manifest[result.name]
    should.exist cachedVersion
    cachedVersion.should.equal result.version
    done()
  
  it 'should create timestamp version if not provided', (done) ->
    result = require path.join @fixtures, './a.json'
    result.dateModified = new Date result.dateModified
    
    beforeTime = Date.now()
    cache.save null, result.name, result.data, result.error
    afterTime = Date.now()
    
    cachedVersion = cache.manifest[result.name]
    
    should.exist cachedVersion
    cachedVersion.should.be.type 'number'
    cachedVersion.should.not.be.above afterTime
    cachedVersion.should.not.be.below beforeTime
    done()
