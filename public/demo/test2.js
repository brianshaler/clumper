define(['demo/test1'], function(test1) {
  return function (str) {
    test1("test2: " + str);
  };
});