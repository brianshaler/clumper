clumper = require '../../'
should = require 'should'
path = require 'path'
require 'mocha'

describe 'server/asset', ->
  #load: load
  #hashFile: hashFile
  #hashFilePathAndData: hashFilePathAndData
  
  it 'should load a file', (done) ->
    fpath = './a.js' # get it? load 'a' file?
    result = require path.join @fixtures, './a.json'
    clumper.asset.load fpath, (err, file) ->
      should.not.exist err
      should.exist file
      should.exist file.data
      file.version.should.equal result.version
      done()

  it 'should respond with an object with an error property if file doesn\'t exist', (done) ->
    fpath = './404.js' # get it? load 'a' file?
    clumper.asset.load fpath, (err, file) ->
      should.not.exist err
      should.exist file
      should.exist file.error
      file.error.should.equal 'ENOENT'
      done()

  it 'should hash file path and contents', (done) ->
    result = require path.join @fixtures, './a.json'
    fpath = './a.js'
    hash = clumper.asset.hashFilePathAndData result.path, result.data
    should.exist hash
    hash.should.equal result.version
    done()





