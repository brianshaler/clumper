path = require 'path'
config = require './config'

module.exports = (name, srcDir) ->
  {baseDir, pathFilter} = config

  name = pathFilter name
  unless name.charAt(0) == '/' or name.charAt(0) == '.'
    name = "/#{name}"

  # add .js to everything because why not..
  unless /\.js$/.test name
    name = "#{name}.js"

  # make sure relative path is *within* base directory
  fullPath = path.resolve (srcDir ? baseDir), name
  unless baseDir == fullPath.substring 0, baseDir.length
    # invalid path! remove all ..'s
    name = name.replace '..', '.'
    fullPath = path.join baseDir, name

  # return relative path
  fullPath.substring baseDir.length
