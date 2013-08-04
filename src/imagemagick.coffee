ChildProcess   = require 'child_process'
{EventEmitter} = require 'events'

class Convert extends EventEmitter
  args = []


  addArg = (addArgs...) ->
    args = args.concat addArgs

  parseSize = (size) ->
    if typeof size is 'object' and size.width? and size.height?
      "#{size.width}x#{size.height}"
    else
      "#{size}"

  parseGeometry = (geometry) ->
    if typeof geometry is 'object'
      if geometry.scale?
        "#{geometry.scale}%"
      else if geometry.area?
        "#{geometry.area}@"
      else if geometry.scaleWidth? and geometry.scaleHeight?
        "#{geometry.scaleWidth}%x#{geometry.scaleHeight}%"
      else if geometry.width? and not geometry.height?
        "#{geometry.width}"
      else if geometry.height? and not geometry.width?
        "x#{geometry.height}"
      # We default to preserve aspect-ratio, so this checks for a `false` `preserveAspect`
      else if geometry.preserveAspect? and (not geometry.preserveAspect) and geometry.width? and geometry.height?
        "#{geometry.width}x#{geometry.height}!"
      else if geometry.width? and geometry.height?
        if geometry.onlyShrink? and geometry.onlyShrink
          "#{geometry.width}x#{geometry.height}>"
        else if geometry.onlyEnlarge? and geometry.onlyEnlarge
          "#{geometry.width}x#{geometry.height}<"
        else if geometry.fill? and geometry.fill
          "#{geometry.width}x#{geometry.height}^"
        else
          "#{geometry.width}x#{geometry.height}"
      else
        "#{geometry}"
    else
      "#{geometry}"


  constructor: ->
    return @


  getArguments: =>
    "#{args.join ' '}"

  run: =>
    ChildProcess.exec "convert #{args.join ' '}", (error, stderr, stdout) =>
      return @emit 'run_error', error  if error
      return @emit 'run_success', stdout
    @

  define: (settings) =>
    addArgs = []
    for key, value of settings
      if typeof value is 'object'
        addArgs.push "-define #{key}:#{subkey}=#{value[subkey]}"  for subkey of value
      else
        addArgs.push "-define #{key}=#{value}"
    addArg addArgs...
    @

  load: (path, firstPageOnly=false) =>
    if firstPageOnly
      addArg "'#{path}[0]'"
    else
      addArg "'#{path}'"
    @

  save: (path, fileType = 'PNG', bits = '') =>
    addArg "'#{fileType}#{bits}:#{path}'"
    @

  strip: =>
    addArg '-strip'
    @

  autoOrient: =>
    addArg '-auto-orient'
    @

  trim: =>
    addArg '-trim'
    @

  quality: (value) =>
    addArg '-quality', "#{value}"
    @

  density: (size) =>
    addArg '-density', parseSize size
    @

  fuzz: (percentage) =>
    addArg '-fuzz', "#{percentage}%"
    @

  repage: (geometry) =>
    if not geometry?
      addArg '+repage'
    else
      addArg '-repage', parseGeometry geometry
    @

  unsharp: (sigma, radius = 0, gain = 1.0, threshold = 0.05) =>
    addArg '-unsharp', "#{radius}x#{sigma}+#{gain}+#{threshold}"
    @

  thumbnail: (size) =>
    addArg '-thumbnail', parseSize size
    @

  font: (path) =>
    addArg '-font', "#{path}"
    @

  background: (color) =>
    addArg '-background', "#{color}"
    @

  fill: (color) =>
    addArg '-fill', "#{color}"
    @

  pointSize: (size) =>
    addArg '-pointsize', "#{size}"
    @

  antialias: =>
    addArg '-antialias'
    @

  pango: (text) =>
    addArg "pango:'#{text}'"
    @

  label: (text) =>
    addArg "label:'#{text}'"
    @

  colors: (amount) =>
    addArg '-colors', "#{amount}"
    @


module.exports =
  convert: ->
    new Convert()

