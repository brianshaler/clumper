clumper = require '../../'
should = require 'should'
request = require 'supertest'
require 'mocha'

describe 'server/middleware', ->
  it 'should return a middleware function', (done) ->
    middle = clumper.middleware @fixtures
    should.exist middle
    (typeof middle).should.equal 'function'
    middle.length.should.equal 3
    done()

  it 'should error when no root given', (done) ->
    try
      clumper.middleware()
    catch err
      should.exist err
      done()

  it 'should not respond with invalid clumper extension', (done) ->
    request @app
      .get '/clumper.lol?files=a.js,b.js'
      .expect 404
      .end done
  
  ###
  it 'should not respond with invalid file extension', (done) ->
    request @app
      .get '/clumper.js?files=a.txt'
      .expect 400
      .end done
  ###
  
  it 'should respond with files via JS', (done) ->
    request @app
      .get '/clumper.js?files=a.js,b.js'
      .expect 'Content-Type', 'application/javascript'
      .expect 200
      .end done

  it 'should respond with files via JSON', (done) ->
    request @app
      .get '/clumper.json?files=a.js,b.js'
      .set 'Accept', 'application/json'
      .expect 'Content-Type', 'application/json'
      .expect 200
      .end done

  it 'should respond with dependencies via JS', (done) ->
    request @app
      .get '/clumper.js?files=c.js'
      .expect 'Content-Type', 'application/javascript'
      .expect 200
      .end done

  it 'should redirect to static file if requesting a single non-existent JS dependency', (done) ->
    request @app
      .get '/clumper.js?files=404'
      .expect 302
      .end done

  it 'should respond with errors if requesting a multiple non-existent JS dependency', (done) ->
    request @app
      .get '/clumper.js?files=404a,404b'
      .expect 'Content-Type', 'application/javascript'
      .expect 200
      .end done

  it 'should respond Not Modified if If-Modified-Since is newer than all files', (done) ->
    request @app
      .get '/clumper.js?files=c.js'
      .set 'If-Modified-Since', (new Date()).toUTCString()
      .expect 304
      .end done

  it 'should respond with only files not in manifest cookie', (done) ->
    request @app
      .get '/clumper.json?files=c.js'
      .set 'cookie', "clumperOldest=#{Date.now()}; clumper=" + JSON.stringify
        'a.js': 'tCkU'
      .expect 200
      .end (err, res) ->
        {files} = JSON.parse res.text
        files.length.should.equal 2
        done err
