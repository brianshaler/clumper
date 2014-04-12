clumper = require '../../'
Dependency = require '../../src/client/dependency'
should = require 'should'
path = require 'path'
require 'mocha'

describe 'client/dependency', ->
  
  it 'should normalize names', ->
    result = 'a.js'
    test1 = 'a'
    test2 = 'a.js'
    test3 = '/a.js'
    test4 = './a.js'
    test5 = '/./a.js'
    
    Dependency.getName(test1).should.equal result
    Dependency.getName(test2).should.equal result
    Dependency.getName(test3).should.equal result
    Dependency.getName(test4).should.equal result
    Dependency.getName(test5).should.equal result
  
  it 'should provide name variations', ->
    names = ['a.js', '/a.js', './a.js', '/./a.js']
    
    resolvedNames = Dependency.getNames 'a'
    
    should.exist resolvedNames
    resolvedNames.length.should.equal names.length
    resolvedNames[0].should.equal names[0]
    resolvedNames[1].should.equal names[1]
    resolvedNames[2].should.equal names[2]
    resolvedNames[3].should.equal names[3]
  
  it 'should set default properties', ->
    name = 'a'
    dep = new Dependency name
    dep.name.should.equal name
    dep.processed.should.equal false
    dep.listeners.length.should.equal 0
    
    should.not.exist dep.error
    should.not.exist dep.data
    #dep.version.should.equal Date.now()
    dep.dateModified.should.equal 0
  
  it 'should notify listeners when processed', ->
    called1 = false
    called2 = false
    
    name = 'a'
    testData = 'test'
    
    dep = new Dependency name
    
    dep.onProcess (err, dep) ->
      should.not.exist err
      should.exist dep
      dep.data.should.equal testData
      called1 = true
    dep.onProcess (err, dep) ->
      should.not.exist err
      should.exist dep
      dep.data.should.equal testData
      called2 = true
    
    dep.process testData
    called1.should.equal true
    called2.should.equal true
  
  it 'should notify listeners when failed', ->
    called1 = false
    called2 = false
    
    name = 'a'
    testError = 'ENOENT'
    
    dep = new Dependency name
    
    dep.onProcess (err, dep) ->
      should.exist err
      dep.error.should.equal testError
      should.exist dep
      should.not.exist dep.data
      called1 = true
    dep.onProcess (err, dep) ->
      should.exist err
      dep.error.should.equal testError
      should.exist dep
      should.not.exist dep.data
      called2 = true
    
    dep.fail testError
    called1.should.equal true
    called2.should.equal true
  