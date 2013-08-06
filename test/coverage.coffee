return unless process.env.COVERAGE is '1'

IGNORE_FILES_REGEX = ///
  (
    test
  )
///

coffee    = require 'coffee-script'
coverage  = require 'coffee-coverage'
fs        = require 'fs'

cover = new coverage.CoverageInstrumentor()

require.extensions['.coffee'] = (module, filename) ->
  file = fs.readFileSync filename, 'utf8'
  opts =
    filename: filename

  if filename.match IGNORE_FILES_REGEX
    content = coffee.compile file, opts
    return module._compile content, filename

  result = cover.instrumentCoffee filename, file
  module._compile result.init + result.js, filename