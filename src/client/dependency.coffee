class Dependency
  constructor: (@name) ->
    @processed = false
    @listeners = []
    
    @error = null
    @data = null
    @fileId = ''
    @version = Date.now()
    @dateModified = 0
  
  onProcess: (callback) =>
    return unless callback
    if @processed
      callback @error, @data
    else
      @listeners.push callback
  
  process: (@data) =>
    @processed = true
    for listener in @listeners
      listener @error, @
    @listeners = []
  
  fail: (@error) =>
    @processed = true
    for listener in @listeners
      listener @error, @
    @listeners = []
  
  @getName: (name) ->
    Dependency.getNames(name)[0]
  
  @getNames: (name) ->
    name = name.replace /^[\/\.]+/, ''
    unless /\.js$/.test name
      name = "#{name}.js"
    names = [
      name
      "/#{name}"
      "./#{name}"
      "/./#{name}"
    ]
  

module.exports = Dependency