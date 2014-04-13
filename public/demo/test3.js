define(function(require) {
  var test2 = require('foobar/demo/test2');
  return function (str) {
    test2("3: " + str);
  };
});