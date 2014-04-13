fs = require 'fs'
gulp = require 'gulp'
gutil = require 'gulp-util'
plumber = require 'gulp-plumber'
watch = require 'gulp-watch'
concat = require 'gulp-concat'
coffee = require 'gulp-coffee'
uglify = require 'gulp-uglify'
browserify = require 'gulp-browserify'
rename = require 'gulp-rename'

# TODO
# lodash -m -o vendor/lodash.custom.js include=map,filter,debounce exports=global

gulp.task 'coffee', ->
  gulp.src "src/**/*.coffee"
  .pipe coffee()
  .pipe gulp.dest './lib'

gulp.task 'client-browserify', ->
  coffeeify = browserify
    standalone: 'clumper'
    transform: ['coffeeify']
    extensions: ['.coffee']
  
  gulp.src 'src/client/index.coffee', read: false
  .pipe coffeeify
  .pipe rename 'client.js'
  .pipe gulp.dest './lib/client'

gulp.task 'build-client', ['client-browserify'], ->
  gulp.src ['vendor/lodash.custom.js', 'lib/client/client.js', 'vendor/require.js', 'lib/client/require.load.js']
  .pipe concat 'clumper.min.js'
  .pipe uglify()
  .pipe gulp.dest './dist'

gulp.task 'watch', ['coffee', 'build-client'], ->
  gulp.watch ['lib/client/**/*.js'], ['build-client']
  
  watch glob: 'src/server/**/*.coffee'
  .pipe plumber()
  .pipe coffee()
  .on 'error', gutil.beep
  .on 'error', gutil.log
  .pipe gulp.dest './lib'
  
  watch glob: 'src/client/**/*.coffee'
  .pipe plumber()
  .pipe coffee()
  .on 'error', gutil.beep
  .on 'error', gutil.log
  .pipe gulp.dest './lib/client'

gulp.task 'default', ['coffee', 'build-client'], ->
