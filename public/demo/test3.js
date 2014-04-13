define(function(require) {
  var test2 = require('demo/test2');
  return function (str) {
    test2("3: " + str);
  };
});