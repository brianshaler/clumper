# clumper

Runtime module bundling, request batching, anticipated dependency loading, and localStorage caching to eliminate extraneous HTTP requests for javascript assets.

It works in requirejs compatible AMD projects by injecting requirejs and hijacking its HTTP loading functionality. Requests can then be batched and if a module is cached in memory or localStorage, it can be evaluated immediately without an HTTP request.

### Important Note

This module has not been thoroughly tested, does not have unit tests, has not been run in every modern browser, does not fallback gracefully for older browsers, and SHOULD NOT be used (yet) in production. It is currently a proof of concept of a way to make AMD applications much more efficient.

## Installing

### Install clumper

`npm install clumper --save`

### Or clone the repo and try out the demo:

#### Install dependencies

`npm install`

#### Build JS assets (make sure you have coffee-script >1.7 and gulp installed)

`gulp`

#### Run the server on port 3000

`npm start`

The basic demo will be running at http://localhost:3000/demo.html


## Usage

### Server

```javascript
var express = require('express');
var clumper = require('clumper');

// Simple configuration
clumper.config.configure({
  baseDir: __dirname + "/public"
});

app = express();

app.use(app.router);
app.use(express.static(__dirname + "/public");

// Add one route to express
app.get('/scripts.:format?', clumper.request);

app.get('/', function (req, res, next) {
  res.redirect('/demo.html');
});

app.listen(3000);
```

### Client

```html
<!-- Include the base library and initial scripts in one request -->
<script src="/scripts.js?include=true&amp;files=demo/test2,other/module,third/module"></script>
<script>
require(['/demo/test2.js'], function (test2) { test2("Demo!"); });
</script>
```

## Tricks

Code can be inlined to execute synchronously using `<script src="/scripts.js?files=...` or you can use requirejs's require() and define() statements, which will trigger a batched request to `/scripts.json?files=`

When testing, you will sometimes need to blow away your localStorage (`localStorage.clear()`) and your cookies (`document.cookie = 'clumper='`). You should also clear your cache, heavily, to prevent 304s from the servers or 200s from the browser's cache.

You can embed multiple &lt;script&gt; tags, in case you want the first to be cached and the second to be dynamic to the page you're landing on. Just make sure the first has `include=true` (prepends clumper client library before modules) and subsequent tags do not.

Requirejs allows you to create aliases (e.g. `app/main` => `/./main.js`) which can confuse clumper's dependency anticipation. On the server, you'll need to write your own transformations to turn aliases into real paths to real files.

```javascript
clumper.config.configure({
  pathFilter: function (path) {
    path = path.replace(/^[\/\.]*app\//, './');
    if (path.charAt(0) != '/') {
      path = "/" + path;
    }
    return path;
  }
});
```

Clumper includes an optional in-memory cache (larger projects may want to use a more optimal key-value store). All javascript files are read and parsed for requires() and defines() in order to anticipate dependencies and send them to the browser before the browser even knows it wants them. Doing this for every request would suck. At the very least, use the basic in-memory cache:

```javascript
clumper.config.configure({
  cache: clumper.basicCache
});
```

Some apps depend on JS assets that don't actually exist on disk. If clumper can't fs-read a path, it will send the browser a 302 redirect to the normal path if it is the only module being requested by a `/scripts.js` request. If there are multiple modules being requested, or if the browser is expecting a JSON response, the clumper client library will see the failure and fall back to loading the file via XHR.

To prevent an extra roundtrip to the server, include the module in the initial &lt;script&gt; tag. That way, the next request will be to the static file.

URLs and caches are invalidated when the server sees a file has changed. However, the server does not watch your files—it will only see a file has changed if the browser does not have it in localStorage, requests the file, and the server-side caching mechanism doesn't have a response. Then, the next response to any request will invalidate old caches. The process is not perfect, but when aggressively caching and trying to eliminate HTTP requests, it becomes difficult to invalidate all layers of cache.

