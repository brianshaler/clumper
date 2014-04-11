path = require 'path'

module.exports = (name, baseDir, pathFilter) ->
  name = pathFilter name
  if name.charAt(0) != '/'
    name = "/#{name}"
  
  # add .js to everything because why not..
  unless /\.js$/.test name
    name = "#{name}.js"
  
  # make sure relative path is *within* base directory
  fullPath = path.resolve "#{baseDir}#{name}"
  unless baseDir == fullPath.substring 0, baseDir.length
    # invalid path!
    name = name.replace '..', '.'
    fullPath = path.resolve "#{baseDir}#{name}"
  
  # return relative path
  fullPath.substring baseDir.length

