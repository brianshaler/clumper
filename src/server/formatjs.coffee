fs = require 'fs'
config = require './config'

template = (files) ->
  """
(function () {
  var data = #{JSON.stringify files};
  if (clumper) {
    clumper.removeItemsOlderThan(#{config.newestFile});
    for (var k in data) {
      clumper.process(data[k].name, data[k].error, data[k].data, data[k].version, (new Date(data[k].dateModified)).getTime());
      clumper.eval(data[k].name);
    }
  }
})()
  """

module.exports = (files, includeClumper, next) ->
  text = template files
  if includeClumper
    fs.readFile "#{__dirname}/public/clumper.js", 'utf-8', (err, contents) ->
      return next err if err
      text = contents + "\n;" + text
      next null, text
  else
    next null, text
