clumper = require '../../'
should = require 'should'
path = require 'path'
require 'mocha'

describe 'server/assetLoader', ->
  it 'a.js should have no dependencies', (done) ->
    moduleName = './a.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      done()

  it 'b.js should have no dependencies', (done) ->
    moduleName = './b.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      done()

  it 'c.js should have dependencies', (done) ->
    moduleName = './c.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 3
      files[0].name.should.equal moduleName
      done()

  it 'a should have name of `a` and path of `/a.js`', (done) ->
    moduleName = 'a'
    modulePath = '/a.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      files[0].path.should.equal modulePath
      done()

  it 'a.js should have name of `a.js` and path of `/a.js`', (done) ->
    moduleName = 'a.js'
    modulePath = '/a.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      files[0].path.should.equal modulePath
      done()

  it './a.js should have name of `./a.js` and path of `/a.js`', (done) ->
    moduleName = './a.js'
    modulePath = '/a.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      files[0].path.should.equal modulePath
      done()

  it '/./a.js should have name of `/./a.js` and path of `/a.js`', (done) ->
    moduleName = '/./a.js'
    modulePath = '/a.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      files[0].path.should.equal modulePath
      done()

  it '../a.js should be flattened to the root', (done) ->
    moduleName = '../a.js'
    resolvedPath = '/a.js'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      files[0].path.should.equal resolvedPath
      done()

  it 'a, ./a.js, and a.js should not be normalized if explicitly requested as different names', (done) ->
    moduleNames = ['a', './a.js', 'a.js']
    clumper.assetLoader moduleNames, (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 3
      files[0].name.should.equal moduleNames[0]
      files[1].name.should.equal moduleNames[1]
      files[2].name.should.equal moduleNames[2]
      done()

  it 'should not include duplicates for cross-over dependencies', (done) ->
    moduleNames = ['./a.js', './b.js', './c.js']
    clumper.assetLoader moduleNames, (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 3
      files[0].name.should.equal moduleNames[0]
      files[1].name.should.equal moduleNames[1]
      files[2].name.should.equal moduleNames[2]
      done()

  it 'jquery should exist with no dependencies', (done) ->
    moduleName = 'jquery'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].path.should.equal "/#{moduleName}.js"
      done()

  it 'react should exist with no dependencies, ignoring require for `./React`', (done) ->
    moduleName = 'react'
    clumper.assetLoader [moduleName], (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 1
      files[0].name.should.equal moduleName
      files[0].path.should.equal "/#{moduleName}.js"
      done()

  it 'case-insensitive duplicates should not be filtered out if actually requested', (done) ->
    moduleNames = ['react', './React']
    clumper.assetLoader moduleNames, (err, files) ->
      should.not.exist err
      should.exist files
      files.length.should.equal 2
      files[0].name.should.equal moduleNames[0]
      files[1].name.should.equal moduleNames[1]
      done()
