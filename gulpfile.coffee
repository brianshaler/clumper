fs = require 'fs'
gulp = require 'gulp'
gutil = require 'gulp-util'
plumber = require 'gulp-plumber'
watch = require 'gulp-watch'
concat = require 'gulp-concat'
coffee = require 'gulp-coffee'
#uglify = require 'gulp-uglify'
#browserify = require 'gulp-browserify'

gulp.task 'build-server', ->
  gulp.src "src/server/**/*.coffee"
  .pipe coffee()
  .pipe gulp.dest './lib'

gulp.task 'compile-client', ->
  gulp.src ['src/client/**/*.coffee', 'src/client/client.coffee']
  .pipe coffee()
  .pipe concat 'client.js'
  .pipe gulp.dest './public'

gulp.task 'build-client', ['compile-client'], ->
  # TODO
  # lodash -m -o vendor/lodash.custom.js include=map,filter,debounce exports=global
  gulp.src ['vendor/require.js', 'vendor/lodash.custom.js', 'public/client.js']
  .pipe concat 'clumper.js'
  .pipe gulp.dest './public'
  .pipe gulp.dest './lib/public'

gulp.task 'watch', ['build-server', 'build-client'], ->
  gulp.watch ['src/client/**/*.coffee'], ['build-client']
  
  watch glob: 'src/server/**/*.coffee'
  .pipe plumber()
  .pipe coffee()
  .on 'error', gutil.beep
  .on 'error', gutil.log
  .pipe gulp.dest './lib'

gulp.task 'default', ['build-server', 'build-client'], ->
