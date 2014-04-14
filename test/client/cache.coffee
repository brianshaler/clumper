clumper = require '../../'
cache = require '../../src/client/cache'
Dependency = require './dependency'
should = require 'should'
path = require 'path'
require 'mocha'

describe 'client/cache', ->
  
  beforeEach ->
    time1 = 100000 * Math.floor Date.now()/100000
    time2 = time1 - 60 * 1000
    time3 = time1 - 120 * 1000
    @module = module = require path.join @fixtures, './a.json'
    @dep1 =
      name: module.name + '1'
      cachedAt: time1
      dateModified: time1
      data: module.data
      error: module.error
      fileId: module.fileId
      version: module.version
    @dep2 =
      name: module.name + '2'
      cachedAt: time3
      dateModified: time3
      data: module.data
      error: module.error
      fileId: module.fileId
      version: module.version
  
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
  
  it 'should remove items older than an input time', (done) ->
    cache.save @dep1
    cache.save @dep2
    
    cache.removeItemsOlderThan (@dep2.cachedAt+@dep1.cachedAt)/2
    
    should.not.exist cache.get @dep2.name
    
    cachedDep = cache.get @dep1.name
    cachedDep.should.equal @dep1.data
    done()
  
  it 'should return the oldest time', (done) ->
    cache.save @dep1
    cache.save @dep2
    @dep2.cachedAt.should.equal cache.getOldestTime()
    done()
