
# hack requirejs to load modules through clumper
@require.load = @requirejs.load = (context, moduleName, url) ->
  clumper.require url, (err, dep) ->
    if !dep? or dep?.error
      # fall back to letting requirejs do it's own thang
      # console.log "fall back to letting requirejs do it's own thang"
      xhr = new XMLHttpRequest()
      xhr.open 'GET', url, true
      xhr.send()
      xhr.onreadystatechange = ->
        if xhr.readyState == 4
          eval xhr.responseText
          name = clumper.getName url
          clumper.saveModule name, xhr.responseText
          context.completeLoad moduleName
    else
      ((module) ->
        module = undefined
        eval dep.data
        context.completeLoad moduleName
      )()
