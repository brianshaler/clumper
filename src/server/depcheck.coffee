module.exports = (data, dependencies = []) ->
  
  mockDefine = (id, arr, cb) ->
    unless typeof id == 'string'
      cb = arr
      arr = id
      id = null
    unless arr instanceof Array
      cb = arr
      arr = []
    if arr?.length > 0
      dependencies = dependencies.concat arr
  
  mockRequire = (depNames) ->
    if typeof depNames == 'string'
      depNames = [depNames]
    if depNames?.length > 0
      dependencies = dependencies.concat depNames
  
  toEval = []
  definePattern = /\bdefine\(([^\)]+)function/g
  requirePattern = /\brequire\(([^,^\)]+)/g
  
  while dep = definePattern.exec data
    toEval.push "mockDefine(#{dep[1]}function() {});"
  
  while dep = requirePattern.exec data
    # make sure it kind of looks like a string or array of strings is being passed
    if /^\s*'|"|\['|\["/.exec dep[1]
      toEval.push "mockRequire(#{dep[1]});"
  
  for code in toEval
    try
      eval code
  
  dependencies