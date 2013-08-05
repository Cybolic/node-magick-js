###*
# Provides the syntax parsers for the ImageMagick options.
#
# @module options
###

ChildProcess   = require 'child_process'
{EventEmitter} = require 'events'


###*
# Provides the indivial formatters for returning strings suitable for the input types defined in ImageMagicks documentation.
#
# @class inputTypes
# @static
###
inputTypes =

  ###*
  # Return integer as String prefixed with '+' for positive numbers and '-' for negative numbers.
  #
  # @method integer
  # @param {Number} int The integer to return.
  # @return {String} int as String prefixed with correct sign.
  ###
  integer: (int) ->
    "#{(if int < 0 then '-' else '+')}#{Math.abs int}"

  ###*
  # Return a `size` argument (Image Geometry).
  #
  # @method size
  # @param {Object} options options for how scaling the image should be done.
  #   @param {Integer} [options.width]
  #     scale output to this width.
  #   @param {Integer} [options.height]
  #     scale output to this height.
  #   @param {Integer} [options.scale]
  #     scale output to this percentage of its original size.
  #   @param {Integer} [options.scaleWidth]
  #     scale output to a width of this percentage of its original size.
  #   @param {Integer} [options.scaleHeight]
  #     scale output to a height of this percentage of its original size.
  #   @param {Boolean} [options.onlyShrink]
  #     only scale output if it is larger than the set `options.width` or `options.height`.
  #   @param {Boolean} [options.onlyEnlarge]
  #     only scale output if it is smaller than the set `options.width` or `options.height`.
  #   @param {Boolean} [options.fill]
  #     scale output to fill the set `options.width` and `options.height` completely, cropping if neccessary.
  #   @param {Boolean} [options.preserveAspect=true]
  #     if `true` always preserve the original aspect-ratio.
  # @return {String} options formatted as a String.
  ###
  size: (options) ->
    if options.scale?
      "#{options.scale}%"
    else if options.area?
      "#{options.area}@"
    else if options.scaleWidth? and options.scaleHeight?
      "#{options.scaleWidth}%x#{options.scaleHeight}%"
    else if options.width? and not options.height?
      "#{options.width}"
    else if options.height? and not options.width?
      "x#{options.height}"
    # We default to preserve aspect-ratio, so this checks for a `false` `preserveAspect`
    else if options.preserveAspect? and (not options.preserveAspect) and options.width? and options.height?
      "#{options.width}x#{options.height}!"
    else if options.width? and options.height?
      if options.onlyShrink? and options.onlyShrink
        "#{options.width}x#{options.height}>"
      else if options.onlyEnlarge? and options.onlyEnlarge
        "#{options.width}x#{options.height}<"
      else if options.fill? and options.fill
        "#{options.width}x#{options.height}^"
      else
        "#{options.width}x#{options.height}"
    else
      if typeof options is 'object'
        throw new Error "`#{ key for key of options }` is not an accepted option"
      else
        "#{options}"

  ###*
  # Return an `offset` argument (Image Geometry).
  #
  # @method offset
  # @param {Object} options options for offsetting the image.
  #   @param {Integer} [options.offsetX]
  #     move image this amount of pixels left or right.
  #   @param {Integer} [options.offsetY]
  #     move image this amount of pixels up or down.
  # @return {String} options formatted as a String.
  ###
  offset: (options) ->
      if options.offsetX? and options.offsetY?
        "#{inputTypes.integer options.offsetX}#{inputTypes.integer options.offsetY}"
      else if options.offsetX?
        "#{inputTypes.integer options.offsetX}+0"
      else if options.offsetY?
        "+0#{inputTypes.integer options.offsetY}"
      else
        ""

  ###*
  # Return a `geometry` argument (Image Geometry). See `size` and `offset` for how to construct the `options` argument.
  #
  # @method geometry
  # @param {Object} options options for scaling or positioning the image.
  # @uses size
  # @uses offset
  # @return {String} options formatted as a String.
  ###
  geometry: (options) ->
    if typeof options is 'object'
      "#{inputTypes.size options}#{inputTypes.offset options}"
    else
      "#{options}"

  ###*
  # Return an `unsharp` argument.
  #
  # @method unsharp
  # @param {Object|Integer} options options for unsharpening or an integer sigma value (in which case defaults will be used for the remaining parameters).
  #   @param {Integer} [options.sigma=2] the
  #    standard deviation of the Gaussian, in pixels.
  #   @param {Integer} [options.radius=0]
  #     the radius of the Gaussian, in pixels,  not counting the center pixel.
  #   @param {Integer} [options.gain=1.0]
  #     the fraction of the difference between the original and the blur image that is added back into the original.
  #   @param {Integer} [options.threshold=0.05]
  #     the threshold, as a fraction of QuantumRange, needed to apply the difference amount.
  # @return {String} options formatted as a String.
  ###
  unsharp: (options) ->
    if typeof options isnt 'object'
      options =
        sigma: options

    options.sigma     ?= 2
    options.radius    ?= 0
    options.gain      ?= 1.0
    options.threshold ?= 0.05

    "#{options.radius}x#{options.sigma}+#{options.gain}+#{options.threshold}"

  ###*
  # Return one or more `define` options and their arguments.
  #
  # @method define
  # @param {Object} definitions
  # @example
  #     define({jpeg: {size:{width:128, height:128}}, showkernel:1})
  #     # ["jpeg:size=128x128", "showkernel=1"]
  # @uses geometry
  # @return {Array} an array of each definition as a String.
  ###
  define: (definitions) ->
    args = []
    for key, value of definitions
      if typeof value is 'object'
        for subkey of value
          if subkey is 'size' or subkey is 'offset'
            value[subkey] = inputTypes.geometry value[subkey]
          args.push "#{key}:#{subkey}=#{value[subkey]}"
      else
        args.push "#{key}=#{value}"
    args

options =
  # adaptively blur pixels; decrease effect near edges
  adaptiveBlur: (geometry) ->
    [ '-adaptive-blur', "'#{inputTypes.geometry geometry}'" ]
  # adaptively resize image with data dependent triangulation.
  adaptiveResize: (geometry) ->
    [ '-adaptive-resize', "'#{inputTypes.geometry geometry}'" ]
  # adaptively sharpen pixels; increase effect near edges
  adaptiveSharpen: (geometry) ->
    [ '-adaptive-sharpen', "'#{inputTypes.geometry geometry}'" ]
  # join images into a single multi-image file
  adjoin: ->
    [ '-adjoin' ]
  # affine transform matrix
  affine: (matrix) ->
    [ '-affine', matrix ]
  # on, activate, off, deactivate, set, opaque, copy", transparent, extract, background, or shape the alpha channel
  alpha: ->
    [ '-alpha' ]
  # text annotate the image with text
  annotate: (geometry) ->
    [ '-annotate', "'#{inputTypes.geometry geometry}'" ]
  # remove pixel-aliasing
  antialias: ->
    [ '-antialias' ]
  # append an image sequence
  append: ->
    [ '-append' ]
  # decipher image with this password
  authenticate: (value) ->
    [ '-authenticate', value ]
  # automagically adjust gamma level of image
  autoGamma: ->
    [ '-auto-gamma' ]
  # automagically adjust color levels of image
  autoLevel: ->
    [ '-auto-level' ]
  # automagically orient image
  autoOrient: ->
    [ '-auto-orient', ]
  # background color
  background: (color) ->
    [ '-background', color ]
  # measure performance
  bench: (iterations) ->
    [ '-bench', iterations ]
  # add bias when convolving an image
  bias: (value) ->
    [ '-bias', value ]
  # force all pixels below the threshold into black
  blackThreshold: (value) ->
    [ '-black-threshold', value ]
  # chromaticity blue primary point
  bluePrimary: (point) ->
    [ '-blue-primary', point ]
  # simulate a scene at nighttime in the moonlight
  blueShift: (factor) ->
    [ '-blue-shift', factor ]
  # reduce image noise and reduce detail levels
  blur: (geometry) ->
    [ '-blur', "'#{inputTypes.geometry geometry}'" ]
  # surround image with a border of color
  border: (geometry) ->
    [ '-border', "'#{inputTypes.geometry geometry}'" ]
  # border color
  bordercolor: (color) ->
    [ '-bordercolor', color ]
  # improve brightness / contrast of the image
  brightnessContrast: (geometry) ->
    [ '-brightness-contrast', "'#{inputTypes.geometry geometry}'" ]
  # assign a caption to an image
  caption: (string) ->
    [ '-caption', string ]
  # color correct with a color decision list
  cdl: (filename) ->
    [ '-cdl', filename ]
  # apply option to select image channels
  channel: (type) ->
    [ '-channel', type ]
  # simulate a charcoal drawing
  charcoal: (radius) ->
    [ '-charcoal', radius ]
  # remove pixels from the image interior
  chop: (geometry) ->
    [ '-chop', "'#{inputTypes.geometry geometry}'" ]
  # set each pixel whose value is below zero to zero and any the pixel whose value is above the quantum range to the quantum range (e.g. 65535) otherwise the pixel value remains unchanged.
  clamp: ->
    [ '-clamp' ]
  # clip along the first path from the 8BIM profile
  clip: ->
    [ '-clip' ]
  # associate clip mask with the image
  clipMask: (filename) ->
    [ '-clip-mask', filename ]
  # clip along a named path from the 8BIM profile
  clipPath: (id) ->
    [ '-clip-path', id ]
  # clone an image
  clone: (index) ->
    [ '-clone', index ]
  # apply a color lookup table to the image
  clut: ->
    [ '-clut' ]
  # improve the contrast in an image by `stretching' the range of intensity value
  contrastStretch: (geometry) ->
    [ '-contrast-stretch', "'#{inputTypes.geometry geometry}'" ]
  # merge a sequence of images
  coalesce: ->
    [ '-coalesce' ]
  # colorize the image with the fill color
  colorize: (value) ->
    [ '-colorize', value ]
  # apply color correction to the image.
  colorMatrix: (matrix) ->
    [ '-color-matrix', matrix ]
  # preferred number of colors in the image
  colors: (value) ->
    [ '-colors', value ]
  # set image colorspace
  colorspace: (type) ->
    [ '-colorspace', type ]
  # combine a sequence of images
  combine: ->
    [ '-combine' ]
  # annotate image with comment
  comment: (string) ->
    [ '-comment', string ]
  # set image composite operator
  compose: (operator) ->
    [ '-compose', operator ]
  # composite image
  composite: ->
    [ '-composite' ]
  # image compression type
  compress: (type) ->
    [ '-compress', type ]
  # enhance or reduce the image contrast
  contrast: ->
    [ '-contrast' ]
  # apply a convolution kernel to the image
  convolve: (coefficients) ->
    [ '-convolve', coefficients ]
  # crop the image
  crop: (geometry) ->
    [ '-crop', "'#{inputTypes.geometry geometry}'" ]
  # cycle the image colormap
  cycle: (amount) ->
    [ '-cycle', amount ]
  # convert cipher pixels to plain
  decipher: (filename) ->
    [ '-decipher', filename ]
  # display copious debugging information
  debug: (events) ->
    [ '-debug', events ]
  # define one or more image format options
  define: (definitions) ->
    ( "-define '#{definition}'" for definition in inputTypes.define definitions )
  # break down an image sequence into constituent parts
  deconstruct: ->
    [ '-deconstruct' ]
  # display the next image after pausing
  delay: (value) ->
    [ '-delay', value ]
  # delete the image from the image sequence
  delete: (index) ->
    [ '-delete', index ]
  # horizontal and vertical density of the image
  density: (geometry) ->
    [ '-density', "'#{inputTypes.geometry geometry}'" ]
  # image depth
  depth: (value) ->
    [ '-depth', value ]
  # reduce the speckles within an image
  despeckle: ->
    [ '-despeckle' ]
  # render text right-to-left or left-to-right
  direction: (type) ->
    [ '-direction', type ]
  # get image or font from this X server
  display: (server) ->
    [ '-display', server ]
  # layer disposal method
  dispose: (method) ->
    [ '-dispose', method ]
  # launch a distributed pixel cache server
  distributeCache: (port) ->
    [ '-distribute-cache', port ]
  # coefficients  distort image
  distort: (type) ->
    [ '-distort', type ]
  # apply error diffusion to image
  dither: (method) ->
    [ '-dither', method ]
  # annotate the image with a graphic primitive
  draw: (string) ->
    [ '-draw', string ]
  # ,indexes  duplicate an image one or more times
  duplicate: (count) ->
    [ '-duplicate', count ]
  # apply a filter to detect edges in the image
  edge: (radius) ->
    [ '-edge', radius ]
  # emboss an image
  emboss: (radius) ->
    [ '-emboss', radius ]
  # convert plain pixels to cipher pixels
  encipher: (filename) ->
    [ '-encipher', filename ]
  # text encoding type
  encoding: (type) ->
    [ '-encoding', type ]
  # endianness (MSB or LSB) of the image
  endian: (type) ->
    [ '-endian', type ]
  # apply a digital filter to enhance a noisy image
  enhance: ->
    [ '-enhance' ]
  # perform histogram equalization to an image
  equalize: ->
    [ '-equalize' ]
  # value  evaluate an arithmetic, relational, or logical expression
  evaluate: (operator) ->
    [ '-evaluate', operator ]
  # evaluate an arithmetic, relational, or logical expression for an image sequence
  evaluateSequence: (operator) ->
    [ '-evaluate-sequence', operator ]
  # set the image size
  extent: (geometry) ->
    [ '-extent', "'#{inputTypes.geometry geometry}'" ]
  # extract area from image
  extract: (geometry) ->
    [ '-extract', "'#{inputTypes.geometry geometry}'" ]
  # render text with this font family
  family: (name) ->
    [ '-family', name ]
  # analyze image features (e.g. contract, correlations, etc.).
  features: (distance) ->
    [ '-features', distance ]
  # implements the discrete Fourier transform (DFT)
  fft: ->
    [ '-fft' ]
  # color to use when filling a graphic primitive
  fill: (color) ->
    [ '-fill', color ]
  # use this filter when resizing an image
  filter: (type) ->
    [ '-filter', type ]
  # flatten a sequence of images
  flatten: ->
    [ '-flatten' ]
  # flip image in the vertical direction
  flip: ->
    [ '-flip' ]
  # color floodfill the image with color
  floodfill: (geometry) ->
    [ '-floodfill', "'#{inputTypes.geometry geometry}'" ]
  # flop image in the horizontal direction
  flop: ->
    [ '-flop' ]
  # render text with this font
  font: (name) ->
    [ '-font', name ]
  # output formatted image characteristics
  format: (string) ->
    [ '-format', string ]
  # surround image with an ornamental border
  frame: (geometry) ->
    [ '-frame', "'#{inputTypes.geometry geometry}'" ]
  # apply a function to the image
  function: (name) ->
    [ '-function', name ]
  # colors within this distance are considered equal
  fuzz: (distance) ->
    [ '-fuzz', distance ]
  # apply mathematical expression to an image channel(s)
  fx: (expression) ->
    [ '-fx', expression ]
  # level of gamma correction
  gamma: (value) ->
    [ '-gamma', value ]
  # reduce image noise and reduce detail levels
  gaussianBlur: (geometry) ->
    [ '-gaussian-blur', "'#{inputTypes.geometry geometry}'" ]
  # preferred size or location of the image
  geometry: (geometry) ->
    [ '-geometry', "'#{inputTypes.geometry geometry}'" ]
  # horizontal and vertical text placement
  gravity: (type) ->
    [ '-gravity', type ]
  # convert image to grayscale
  grayscale: (method) ->
    [ '-grayscale', method ]
  # chromaticity green primary point
  greenPrimary: (point) ->
    [ '-green-primary', point ]
  # print program options
  help: ->
    [ '-help' ]
  # identify the format and characteristics of the image
  identify: ->
    [ '-identify' ]
  # implements the inverse discrete Fourier transform (DFT)
  ift: ->
    [ '-ift' ]
  # implode image pixels about the center
  implode: (amount) ->
    [ '-implode', amount ]
  # insert last image into the image sequence
  insert: (index) ->
    [ '-insert', index ]
  # method to generate an intensity value from a pixel
  intensity: (method) ->
    [ '-intensity', method ]
  # type of rendering intent when managing the image color
  intent: (type) ->
    [ '-intent', type ]
  # type of image interlacing scheme
  interlace: (type) ->
    [ '-interlace', type ]
  # the space between two text lines
  interlineSpacing: (value) ->
    [ '-interline-spacing', value ]
  # pixel color interpolation method
  interpolate: (method) ->
    [ '-interpolate', method ]
  # the space between two words
  interwordSpacing: (value) ->
    [ '-interword-spacing', value ]
  # the space between two characters
  kerning: (value) ->
    [ '-kerning', value ]
  # assign a label to an image
  label: (string) ->
    [ '-label', string ]
  # local adaptive thresholding
  lat: (geometry) ->
    [ '-lat', "'#{inputTypes.geometry geometry}'" ]
  # optimize or compare image layers
  layers: (method) ->
    [ '-layers', method ]
  # adjust the level of image contrast
  level: (value) ->
    [ '-level', value ]
  # value pixel cache resource limit
  limit: (type) ->
    [ '-limit', type ]
  # linear with saturation histogram stretch
  linearStretch: (geometry) ->
    [ '-linear-stretch', "'#{inputTypes.geometry geometry}'" ]
  # rescale image with seam-carving
  liquidRescale: (geometry) ->
    [ '-liquid-rescale', "'#{inputTypes.geometry geometry}'" ]
  # format of debugging information
  log: (format) ->
    [ '-log', format ]
  # add Netscape loop extension to your GIF animation
  loop: (iterations) ->
    [ '-loop', iterations ]
  # associate a mask with the image
  mask: (filename) ->
    [ '-mask', filename ]
  # frame color
  mattecolor: (color) ->
    [ '-mattecolor', color ]
  # apply a median filter to the image
  median: (radius) ->
    [ '-median', radius ]
  # make each pixel the 'predominant color' of the neighborhood
  mode: (radius) ->
    [ '-mode', radius ]
  # vary the brightness, saturation, and hue
  modulate: (value) ->
    [ '-modulate', value ]
  # progress
  monitor: (monitor) ->
    [ '-monitor',  monitor ]
  # image to black and white
  monochrome: (transform) ->
    [ '-monochrome', transform ]
  # morph an image sequence
  morph: (value) ->
    [ '-morph', value ]
  # kernel apply a morphology method to the image
  morphology: (method) ->
    [ '-morphology', method ]
  # simulate motion blur
  motionBlur: (geometry) ->
    [ '-motion-blur', "'#{inputTypes.geometry geometry}'" ]
  # replace each pixel with its complementary color
  negate: ->
    [ '-negate' ]
  # add or reduce noise in an image
  noise: (radius) ->
    [ '-noise', radius ]
  # transform image to span the full range of colors
  normalize: ->
    [ '-normalize' ]
  # change this color to the fill color
  opaque: (color) ->
    [ '-opaque', color ]
  # ordered dither the image
  orderedDither: (NxN) ->
    [ '-ordered-dither', NxN ]
  # image orientation
  orient: (type) ->
    [ '-orient', type ]
  # size and location of an image canvas (setting)
  page: (geometry) ->
    [ '-page', "'#{inputTypes.geometry geometry}'" ]
  # simulate an oil painting
  paint: (radius) ->
    [ '-paint', radius ]
  # set each pixel whose value is less than |epsilon| to -epsilon or epsilon (whichever is closer) otherwise the pixel value remains unchanged.
  perceptible: ->
    [ '-perceptible' ]
  # efficiently determine image attributes
  ping: ->
    [ '-ping' ]
  # font point size
  pointsize: (value) ->
    [ '-pointsize', value ]
  # simulate a Polaroid picture
  polaroid: (angle) ->
    [ '-polaroid', angle ]
  # build a polynomial from the image sequence and the corresponding terms (coefficients and degree pairs).
  poly: (terms) ->
    [ '-poly', terms ]
  # reduce the image to a limited number of color levels
  posterize: (levels) ->
    [ '-posterize', levels ]
  # set the maximum number of significant digits to be printed
  precision: (value) ->
    [ '-precision', value ]
  # image preview type
  preview: (type) ->
    [ '-preview', type ]
  # interpret string and print to console
  print: (string) ->
    [ '-print', string ]
  # -filter process the image with a custom image filter
  process: (image) ->
    [ '-process', image ]
  # add, delete, or apply an image profile
  profile: (filename) ->
    [ '-profile', filename ]
  # JPEG/MIFF/PNG compression level
  quality: (value) ->
    [ '-quality', value ]
  # reduce image colors in this colorspace
  quantize: (colorspace) ->
    [ '-quantize', colorspace ]
  # suppress all warning messages
  quiet: ->
    [ '-quiet' ]
  # radial blur the image
  radialBlur: (angle) ->
    [ '-radial-blur', angle ]
  # lighten/darken image edges to create a 3-D effect
  raise: (value) ->
    [ '-raise', value ]
  # ,high  random threshold the image
  randomThreshold: (low) ->
    [ '-random-threshold', low ]
  # chromaticity red primary point
  redPrimary: (point) ->
    [ '-red-primary', point ]
  # attention to warning messages.
  regardWarnings: (pay) ->
    [ '-regard-warnings',  pay ]
  # apply options to a portion of the image
  region: (geometry) ->
    [ '-region', "'#{inputTypes.geometry geometry}'" ]
  # transform image colors to match this set of colors
  remap: (filename) ->
    [ '-remap', filename ]
  # render vector graphics
  render: ->
    [ '-render' ]
  # size and location of an image canvas
  repage: (geometry) ->
    [ '-repage', "'#{inputTypes.geometry geometry}'" ]
  # change the resolution of an image
  resample: (geometry) ->
    [ '-resample', "'#{inputTypes.geometry geometry}'" ]
  # resize the image
  resize: (geometry) ->
    [ '-resize', "'#{inputTypes.geometry geometry}'" ]
  # settings remain in effect until parenthesis boundary.
  respectParentheses: ->
    [ '-respect-parentheses' ]
  # roll an image vertically or horizontally
  roll: (geometry) ->
    [ '-roll', "'#{inputTypes.geometry geometry}'" ]
  # apply Paeth rotation to the image
  rotate: (degrees) ->
    [ '-rotate', degrees ]
  # scale image with pixel sampling
  sample: (geometry) ->
    [ '-sample', "'#{inputTypes.geometry geometry}'" ]
  # horizontal and vertical sampling factor
  samplingFactor: (geometry) ->
    [ '-sampling-factor', "'#{inputTypes.geometry geometry}'" ]
  # scale the image
  scale: (geometry) ->
    [ '-scale', "'#{inputTypes.geometry geometry}'" ]
  # image scene number
  scene: (value) ->
    [ '-scene', value ]
  # seed a new sequence of pseudo-random numbers
  seed: (value) ->
    [ '-seed', value ]
  # segment an image
  segment: (values) ->
    [ '-segment', values ]
  # selectively blur pixels within a contrast threshold
  selectiveBlur: (geometry) ->
    [ '-selective-blur', "'#{inputTypes.geometry geometry}'" ]
  # separate an image channel into a grayscale image
  separate: ->
    [ '-separate' ]
  # simulate a sepia-toned photo
  sepiaTone: (threshold) ->
    [ '-sepia-tone', threshold ]
  # value  set an image attribute
  set: (attribute) ->
    [ '-set', attribute ]
  # shade the image using a distant light source
  shade: (degrees) ->
    [ '-shade', degrees ]
  # simulate an image shadow
  shadow: (geometry) ->
    [ '-shadow', "'#{inputTypes.geometry geometry}'" ]
  # sharpen the image
  sharpen: (geometry) ->
    [ '-sharpen', "'#{inputTypes.geometry geometry}'" ]
  # shave pixels from the image edges
  shave: (geometry) ->
    [ '-shave', "'#{inputTypes.geometry geometry}'" ]
  # slide one edge of the image along the X or Y axis
  shear: (geometry) ->
    [ '-shear', "'#{inputTypes.geometry geometry}'" ]
  # increase the contrast without saturating highlights or shadows
  sigmoidalContrast: (geometry) ->
    [ '-sigmoidal-contrast', "'#{inputTypes.geometry geometry}'" ]
  # smush an image sequence together
  smush: (offset) ->
    [ '-smush', offset ]
  # width and height of image
  size: (geometry) ->
    [ '-size', "'#{inputTypes.geometry geometry}'" ]
  # simulate a pencil sketch
  sketch: (geometry) ->
    [ '-sketch', "'#{inputTypes.geometry geometry}'" ]
  # negate all pixels above the threshold level
  solarize: (threshold) ->
    [ '-solarize', threshold ]
  # splice the background color into the image
  splice: (geometry) ->
    [ '-splice', "'#{inputTypes.geometry geometry}'" ]
  # displace image pixels by a random amount
  spread: (radius) ->
    [ '-spread', radius ]
  # geometry  replace each pixel with corresponding statistic from the neighborhood
  statistic: (type) ->
    [ '-statistic', type ]
  # strip image of all profiles and comments
  strip: ->
    [ '-strip' ]
  # graphic primitive stroke color
  stroke: (color) ->
    [ '-stroke', color ]
  # graphic primitive stroke width
  strokewidth: (value) ->
    [ '-strokewidth', value ]
  # render text with this font stretch
  stretch: (type) ->
    [ '-stretch', type ]
  # render text with this font style
  style: (type) ->
    [ '-style', type ]
  # swap two images in the image sequence
  swap: (indexes) ->
    [ '-swap', indexes ]
  # swirl image pixels about the center
  swirl: (degrees) ->
    [ '-swirl', degrees ]
  # image to storage device
  synchronize: (synchronize) ->
    [ '-synchronize',  synchronize ]
  # mark the image as modified
  taint: ->
    [ '-taint' ]
  # name of texture to tile onto the image background
  texture: (filename) ->
    [ '-texture', filename ]
  # threshold the image
  threshold: (value) ->
    [ '-threshold', value ]
  # create a thumbnail of the image
  thumbnail: (geometry) ->
    [ '-thumbnail', "'#{inputTypes.geometry geometry}'" ]
  # tile image when filling a graphic primitive
  tile: (filename) ->
    [ '-tile', filename ]
  # set the image tile offset
  tileOffset: (geometry) ->
    [ '-tile-offset', "'#{inputTypes.geometry geometry}'" ]
  # tint the image with the fill color
  tint: (value) ->
    [ '-tint', value ]
  # affine transform image
  transform: ->
    [ '-transform' ]
  # make this color transparent within the image
  transparent: (color) ->
    [ '-transparent', color ]
  # transparent color
  transparentColor: (color) ->
    [ '-transparent-color', color ]
  # flip image in the vertical direction and rotate 90 degrees
  transpose: ->
    [ '-transpose' ]
  # flop image in the horizontal direction and rotate 270 degrees
  transverse: ->
    [ '-transverse' ]
  # color tree depth
  treedepth: (value) ->
    [ '-treedepth', value ]
  # trim image edges
  trim: ->
    [ '-trim' ]
  # image type
  type: (type) ->
    [ '-type', type ]
  # annotation bounding box color
  undercolor: (color) ->
    [ '-undercolor', color ]
  # discard all but one of any pixel color.
  uniqueColors: ->
    [ '-unique-colors' ]
  # the units of image resolution
  units: (type) ->
    [ '-units', type ]
  # sharpen the image
  unsharp: (unsharp) =>
    [ '-unsharp', "'#{inputTypes.unsharp unsharp}'" ]
  # print detailed information about the image
  verbose: ->
    [ '-verbose' ]
  # print version information
  version: ->
    [ '-version' ]
  # FlashPix viewing transforms
  view: ->
    [ '-view' ]
  # soften the edges of the image in vignette style
  vignette: (geometry) ->
    [ '-vignette', "'#{inputTypes.geometry geometry}'" ]
  # access method for pixels outside the boundaries of the image
  virtualPixel: (method) ->
    [ '-virtual-pixel', method ]
  # alter an image along a sine wave
  wave: (geometry) ->
    [ '-wave', "'#{inputTypes.geometry geometry}'" ]
  # render text with this font weight
  weight: (type) ->
    [ '-weight', type ]
  # chromaticity white point
  whitePoint: (point) ->
    [ '-white-point', point ]
  # force all pixels above the threshold into white
  whiteThreshold: (value) ->
    [ '-white-threshold', value ]
  # write images to this file
  write: (filename) ->
    [ '-write', filename ]
  # CUSTOM: Add custom arguments
  add: ->
    arguments


class Convert extends EventEmitter

  addArgs = (args...) ->
    this.arguments = this.arguments.concat args

  optionToChainable = (option, func) ->
    this[option] = ((func) ->
      ->
        # Add argument as a reset switch if the only argument is a Boolean
        if arguments.length? and arguments.length is 1 and typeof arguments[0] is 'boolean'
          args = (func.call @, '').slice 0, 1
          if args.length and args.length > 0
            args[0] = args[0].replace /^-/, '+'
          addArgs.apply @, args
        # Else add normally
        else
          addArgs.apply @, func.apply @, arguments
        @
    ).call this, func

  constructor: ->
    @arguments = []
    callback = null

    # Add available options as chainable functions of this object
    for option, func of options
      optionToChainable.call @, option, func

    # If arguments were provided, use each object as the name of the option to call and its value as the arguments
    if arguments? and arguments.length? and arguments.length > 0
      for arg in arguments
        if typeof arg is 'object'
          for option, args of arg
            throw new Error "No such option `#{option}`"  if not @[option]?
            @[option].call @, args
        else if typeof arg is 'string'
          throw new Error "No such option `#{arg}`"  if not @[arg]?
          @[arg].call @
        else if typeof arg is 'function'
          callback = arg
        else
          throw new Error "Unsupported argument type `#{typeof arg}` of argument `#{arg}`"

      @.run callback
    @

  run: (callback) =>
    ChildProcess.exec "convert #{@arguments.join ' '}", (error, stderr, stdout) =>
      if callback
        callback error, stdout, stderr
      else
        return @emit 'run_error', error  if error
        return @emit 'run_success', stdout
    @


module.exports =
  inputTypes : inputTypes
  options    : options
  convert: ->
    new Convert arguments...
