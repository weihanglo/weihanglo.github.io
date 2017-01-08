const gulp = require('gulp')
const {exec} = require('child_process')

gulp.watch('**', (cb) => {
  exec('hexo clean & hexo g -f', (err, stdout, stderr) => {
    console.log(stdout);
    console.log(stderr);
    cb(err);
  });
});

gulp.task('default', ['watch']);
