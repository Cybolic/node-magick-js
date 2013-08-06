###*
# Setup arguments for and/or run ImageMagick commands.
#
# @module ImageMagick
# @class ImageMagick
# @main ImageMagick
###

ChildProcess   = require 'child_process'
{EventEmitter} = require 'events'


###*
# Provides the indivial formatters for returning strings suitable for the input types defined in ImageMagicks documentation.
#
# @class inputTypes
# @static
###
INPUT_TYPES =

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
  #   @param {Integer} [options.opacity]
  #     for `shadow`, give the shadow this amount of opacity in percentage.
  #   @param {Integer} [options.sigma]
  #     for `shadow`, blur the shadow this amount of pixels
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
    if options.opacity? and options.sigma?
      "#{options.opacity}x#{options.sigma}"
    else if options.opacity?
      "#{options.opacity}"
    else if options.scale?
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
  #   @param {Boolean} [options.usePercentage]
  #     if `true` use offsetX and/or offsetY as percentage values.
  # @return {String} options formatted as a String.
  ###
  offset: (options) ->
    if options.offsetX? or options.offsetY?
      options.offsetX ?= 0
      options.offsetY ?= 0
      if options.usePercentage
        "#{INPUT_TYPES.integer options.offsetX}#{INPUT_TYPES.integer options.offsetY}%"
      else
        "#{INPUT_TYPES.integer options.offsetX}#{INPUT_TYPES.integer options.offsetY}"
    else
      ""

  ###*
  # Return a `geometry` argument (Image Geometry). See `size` and `offset` for how to construct the `options` argument.
  #
  # @method geometry
  # @param {Object} options options for scaling or positioning the image.
  # @uses size
  # @uses offset
  # @type Geometry
  # @return {String} options formatted as a String.
  ###
  geometry: (options) ->
    if typeof options is 'object'
      "#{INPUT_TYPES.size options}#{INPUT_TYPES.offset options}"
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
            value[subkey] = INPUT_TYPES.geometry value[subkey]
          args.push "#{key}:#{subkey}=#{value[subkey]}"
      else
        args.push "#{key}=#{value}"
    args


###*
# Provides functions for calling each of ImageMagicks options with correct argument parsing.
# Each function takes one argument and returns an Array of Strings suitable for the CLI command.
#
# @class Options
# @for Command
# @static
# @private
# @protected
###
OPTIONS =
  ###*
  # Adaptively blur pixels; decrease effect near edges
  # @method adaptiveBlur
  # @chainable
  # @param {Object|String} geometry
  ###
  adaptiveBlur: (geometry) ->
    [ '-adaptive-blur', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Adaptively resize image with data dependent triangulation.
  # @method adaptiveResize
  # @chainable
  # @param {Object|String} geometry
  ###
  adaptiveResize: (geometry) ->
    [ '-adaptive-resize', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Adaptively sharpen pixels; increase effect near edges
  # @method adaptiveSharpen
  # @chainable
  # @param {Object|String} geometry
  ###
  adaptiveSharpen: (geometry) ->
    [ '-adaptive-sharpen', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Join images into a single multi-image file
  # @method adjoin
  # @chainable
  ###
  adjoin: ->
    [ '-adjoin' ]
  ###*
  # Affine transform matrix
  # @method affine
  # @chainable
  # @param {String} matrix
  ###
  affine: (matrix) ->
    [ '-affine', matrix ]
  ###*
  # On, activate, off, deactivate, set, opaque, copy", transparent, extract, background, or shape the alpha channel
  # @method alpha
  # @chainable
  ###
  alpha: ->
    [ '-alpha' ]
  ###*
  # Text annotate the image with text
  # @method annotate
  # @chainable
  # @param {Object|String} geometry
  ###
  annotate: (geometry) ->
    [ '-annotate', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Remove pixel-aliasing
  # @method antialias
  # @chainable
  ###
  antialias: ->
    [ '-antialias' ]
  ###*
  # Append an image sequence
  # @method append
  # @chainable
  ###
  append: ->
    [ '-append' ]
  ###*
  # Decipher image with this password
  # @method authenticate
  # @chainable
  # @param {String} value
  ###
  authenticate: (value) ->
    [ '-authenticate', value ]
  ###*
  # Automagically adjust gamma level of image
  # @method autoGamma
  # @chainable
  ###
  autoGamma: ->
    [ '-auto-gamma' ]
  ###*
  # Automagically adjust color levels of image
  # @method autoLevel
  # @chainable
  ###
  autoLevel: ->
    [ '-auto-level' ]
  ###*
  # Automagically orient image
  # @method autoOrient
  # @chainable
  ###
  autoOrient: ->
    [ '-auto-orient', ]
  ###*
  # Background color
  # @method background
  # @chainable
  # @param {String} color
  ###
  background: (color) ->
    [ '-background', color ]
  ###*
  # Measure performance
  # @method bench
  # @chainable
  # @param {Integer} iterations
  ###
  bench: (iterations) ->
    [ '-bench', iterations ]
  ###*
  # Add bias when convolving an image
  # @method bias
  # @chainable
  # @param {Integer} value
  ###
  bias: (value) ->
    [ '-bias', value ]
  ###*
  # Force all pixels below the threshold into black
  # @method blackThreshold
  # @chainable
  # @param {Integer} value
  ###
  blackThreshold: (value) ->
    [ '-black-threshold', value ]
  ###*
  # Chromaticity blue primary point
  # @method bluePrimary
  # @chainable
  # @param {String} point
  ###
  bluePrimary: (point) ->
    [ '-blue-primary', point ]
  ###*
  # Simulate a scene at nighttime in the moonlight
  # @method blueShift
  # @chainable
  # @param {Integer} factor
  ###
  blueShift: (factor) ->
    [ '-blue-shift', factor ]
  ###*
  # Reduce image noise and reduce detail levels
  # @method blur
  # @chainable
  # @param {Object|String} geometry
  ###
  blur: (geometry) ->
    [ '-blur', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Surround image with a border of color
  # @method border
  # @chainable
  # @param {Object|String} geometry
  ###
  border: (geometry) ->
    [ '-border', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Border color
  # @method bordercolor
  # @chainable
  # @param {String} color
  ###
  bordercolor: (color) ->
    [ '-bordercolor', color ]
  ###*
  # Improve brightness / contrast of the image
  # @method brightnessContrast
  # @chainable
  # @param {Object|String} geometry
  ###
  brightnessContrast: (geometry) ->
    [ '-brightness-contrast', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Assign a caption to an image
  # @method caption
  # @chainable
  # @param {String} string
  ###
  caption: (string) ->
    [ '-caption', string ]
  ###*
  # Color correct with a color decision list
  # @method cdl
  # @chainable
  # @param {String} filename
  ###
  cdl: (filename) ->
    [ '-cdl', filename ]
  ###*
  # Apply option to select image channels
  # @method channel
  # @chainable
  # @param {String} type
  ###
  channel: (type) ->
    [ '-channel', type ]
  ###*
  # Simulate a charcoal drawing
  # @method charcoal
  # @chainable
  # @param {Integer} radius
  ###
  charcoal: (radius) ->
    [ '-charcoal', radius ]
  ###*
  # Remove pixels from the image interior
  # @method chop
  # @chainable
  # @param {Object|String} geometry
  ###
  chop: (geometry) ->
    [ '-chop', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Set each pixel whose value is below zero to zero and any the pixel whose value is above the quantum range to the quantum range (e.g. 65535) otherwise the pixel value remains unchanged.
  # @method clamp
  # @chainable
  ###
  clamp: ->
    [ '-clamp' ]
  ###*
  # Clip along the first path from the 8BIM profile
  # @method clip
  # @chainable
  ###
  clip: ->
    [ '-clip' ]
  ###*
  # Associate clip mask with the image
  # @method clipMask
  # @chainable
  # @param {String} filename
  ###
  clipMask: (filename) ->
    [ '-clip-mask', filename ]
  ###*
  # Clip along a named path from the 8BIM profile
  # @method clipPath
  # @chainable
  # @param {Integer} id
  ###
  clipPath: (id) ->
    [ '-clip-path', id ]
  ###*
  # Clone an image
  # @method clone
  # @chainable
  # @param {Integer} index
  ###
  clone: (index) ->
    [ '-clone', index ]
  ###*
  # Apply a color lookup table to the image
  # @method clut
  # @chainable
  ###
  clut: ->
    [ '-clut' ]
  ###*
  # Improve the contrast in an image by `stretching' the range of intensity value
  # @method contrastStretch
  # @chainable
  # @param {Object|String} geometry
  ###
  contrastStretch: (geometry) ->
    [ '-contrast-stretch', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Merge a sequence of images
  # @method coalesce
  # @chainable
  ###
  coalesce: ->
    [ '-coalesce' ]
  ###*
  # Colorize the image with the fill color
  # @method colorize
  # @chainable
  # @param {Integer} value
  ###
  colorize: (value) ->
    [ '-colorize', value ]
  ###*
  # Apply color correction to the image.
  # @method colorMatrix
  # @chainable
  # @param {String} matrix
  ###
  colorMatrix: (matrix) ->
    [ '-color-matrix', matrix ]
  ###*
  # Preferred number of colors in the image
  # @method colors
  # @chainable
  # @param {Integer} value
  ###
  colors: (value) ->
    [ '-colors', value ]
  ###*
  # Set image colorspace
  # @method colorspace
  # @chainable
  # @param {String} type
  ###
  colorspace: (type) ->
    [ '-colorspace', type ]
  ###*
  # Combine a sequence of images
  # @method combine
  # @chainable
  ###
  combine: ->
    [ '-combine' ]
  ###*
  # Annotate image with comment
  # @method comment
  # @chainable
  # @param {String} string
  ###
  comment: (string) ->
    [ '-comment', string ]
  ###*
  # Set image composite operator
  # @method compose
  # @chainable
  # @param {Integer} operator
  ###
  compose: (operator) ->
    [ '-compose', operator ]
  ###*
  # Composite image
  # @method composite
  # @chainable
  ###
  composite: ->
    [ '-composite' ]
  ###*
  # Image compression type
  # @method compress
  # @chainable
  # @param {String} type
  ###
  compress: (type) ->
    [ '-compress', type ]
  ###*
  # Enhance or reduce the image contrast
  # @method contrast
  # @chainable
  ###
  contrast: ->
    [ '-contrast' ]
  ###*
  # Apply a convolution kernel to the image
  # @method convolve
  # @chainable
  # @param {Integer} coefficients
  ###
  convolve: (coefficients) ->
    [ '-convolve', coefficients ]
  ###*
  # Crop the image
  # @method crop
  # @chainable
  # @param {Object|String} geometry
  ###
  crop: (geometry) ->
    [ '-crop', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Cycle the image colormap
  # @method cycle
  # @chainable
  # @param {Integer} amount
  ###
  cycle: (amount) ->
    [ '-cycle', amount ]
  ###*
  # Convert cipher pixels to plain
  # @method decipher
  # @chainable
  # @param {String} filename
  ###
  decipher: (filename) ->
    [ '-decipher', filename ]
  ###*
  # Display copious debugging information
  # @method debug
  # @chainable
  # @param {Integer} events
  ###
  debug: (events) ->
    [ '-debug', events ]
  ###*
  # Define one or more image format options
  # @method define
  # @chainable
  # @param {Integer} definitions
  ###
  define: (definitions) ->
    ( "-define '#{definition}'" for definition in INPUT_TYPES.define definitions )
  ###*
  # Break down an image sequence into constituent parts
  # @method deconstruct
  # @chainable
  ###
  deconstruct: ->
    [ '-deconstruct' ]
  ###*
  # Display the next image after pausing
  # @method delay
  # @chainable
  # @param {Integer} value
  ###
  delay: (value) ->
    [ '-delay', value ]
  ###*
  # Delete the image from the image sequence
  # @method delete
  # @chainable
  # @param {Integer} index
  ###
  delete: (index) ->
    [ '-delete', index ]
  ###*
  # Horizontal and vertical density of the image
  # @method density
  # @chainable
  # @param {Object|String} geometry
  ###
  density: (geometry) ->
    [ '-density', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Image depth
  # @method depth
  # @chainable
  # @param {Integer} value
  ###
  depth: (value) ->
    [ '-depth', value ]
  ###*
  # Reduce the speckles within an image
  # @method despeckle
  # @chainable
  ###
  despeckle: ->
    [ '-despeckle' ]
  ###*
  # Render text right-to-left or left-to-right
  # @method direction
  # @chainable
  # @param {String} type
  ###
  direction: (type) ->
    [ '-direction', type ]
  ###*
  # Get image or font from this X server
  # @method display
  # @chainable
  # @param {Integer} server
  ###
  display: (server) ->
    [ '-display', server ]
  ###*
  # Layer disposal method
  # @method dispose
  # @chainable
  # @param {String} method
  ###
  dispose: (method) ->
    [ '-dispose', method ]
  ###*
  # Launch a distributed pixel cache server
  # @method distributeCache
  # @chainable
  # @param {Integer} port
  ###
  distributeCache: (port) ->
    [ '-distribute-cache', port ]
  ###*
  # Coefficients  distort image
  # @method distort
  # @chainable
  # @param {String} type
  ###
  distort: (type) ->
    [ '-distort', type ]
  ###*
  # Apply error diffusion to image
  # @method dither
  # @chainable
  # @param {String} method
  ###
  dither: (method) ->
    [ '-dither', method ]
  ###*
  # Annotate the image with a graphic primitive
  # @method draw
  # @chainable
  # @param {String} string
  ###
  draw: (string) ->
    [ '-draw', string ]
  ###*
  # ,indexes  duplicate an image one or more times
  # @method duplicate
  # @chainable
  # @param {Integer} count
  ###
  duplicate: (count) ->
    [ '-duplicate', count ]
  ###*
  # Apply a filter to detect edges in the image
  # @method edge
  # @chainable
  # @param {Integer} radius
  ###
  edge: (radius) ->
    [ '-edge', radius ]
  ###*
  # Emboss an image
  # @method emboss
  # @chainable
  # @param {Integer} radius
  ###
  emboss: (radius) ->
    [ '-emboss', radius ]
  ###*
  # Convert plain pixels to cipher pixels
  # @method encipher
  # @chainable
  # @param {String} filename
  ###
  encipher: (filename) ->
    [ '-encipher', filename ]
  ###*
  # Text encoding type
  # @method encoding
  # @chainable
  # @param {String} type
  ###
  encoding: (type) ->
    [ '-encoding', type ]
  ###*
  # Endianness (MSB or LSB) of the image
  # @method endian
  # @chainable
  # @param {String} type
  ###
  endian: (type) ->
    [ '-endian', type ]
  ###*
  # Apply a digital filter to enhance a noisy image
  # @method enhance
  # @chainable
  ###
  enhance: ->
    [ '-enhance' ]
  ###*
  # Perform histogram equalization to an image
  # @method equalize
  # @chainable
  ###
  equalize: ->
    [ '-equalize' ]
  ###*
  # Value  evaluate an arithmetic, relational, or logical expression
  # @method evaluate
  # @chainable
  # @param {Integer} operator
  ###
  evaluate: (operator) ->
    [ '-evaluate', operator ]
  ###*
  # Evaluate an arithmetic, relational, or logical expression for an image sequence
  # @method evaluateSequence
  # @chainable
  # @param {Integer} operator
  ###
  evaluateSequence: (operator) ->
    [ '-evaluate-sequence', operator ]
  ###*
  # Set the image size
  # @method extent
  # @chainable
  # @param {Object|String} geometry
  ###
  extent: (geometry) ->
    [ '-extent', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Extract area from image
  # @method extract
  # @chainable
  # @param {Object|String} geometry
  ###
  extract: (geometry) ->
    [ '-extract', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Render text with this font family
  # @method family
  # @chainable
  # @param {String} name
  ###
  family: (name) ->
    [ '-family', name ]
  ###*
  # Analyze image features (e.g. contract, correlations, etc.).
  # @method features
  # @chainable
  # @param {Integer} distance
  ###
  features: (distance) ->
    [ '-features', distance ]
  ###*
  # Implements the discrete Fourier transform (DFT)
  # @method fft
  # @chainable
  ###
  fft: ->
    [ '-fft' ]
  ###*
  # Color to use when filling a graphic primitive
  # @method fill
  # @chainable
  # @param {String} color
  ###
  fill: (color) ->
    [ '-fill', color ]
  ###*
  # Use this filter when resizing an image
  # @method filter
  # @chainable
  # @param {String} type
  ###
  filter: (type) ->
    [ '-filter', type ]
  ###*
  # Flatten a sequence of images
  # @method flatten
  # @chainable
  ###
  flatten: ->
    [ '-flatten' ]
  ###*
  # Flip image in the vertical direction
  # @method flip
  # @chainable
  ###
  flip: ->
    [ '-flip' ]
  ###*
  # Color floodfill the image with color
  # @method floodfill
  # @chainable
  # @param {Object|String} geometry
  ###
  floodfill: (geometry) ->
    [ '-floodfill', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Flop image in the horizontal direction
  # @method flop
  # @chainable
  ###
  flop: ->
    [ '-flop' ]
  ###*
  # Render text with this font
  # @method font
  # @chainable
  # @param {String} name name or path of font to use
  ###
  font: (name) ->
    [ '-font', name ]
  ###*
  # Output formatted image characteristics
  # @method format
  # @chainable
  # @param {String} string
  ###
  format: (string) ->
    [ '-format', string ]
  ###*
  # Surround image with an ornamental border
  # @method frame
  # @chainable
  # @param {Object|String} geometry
  ###
  frame: (geometry) ->
    [ '-frame', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Apply a function to the image
  # @method function
  # @chainable
  # @param {String} name
  ###
  function: (name) ->
    [ '-function', name ]
  ###*
  # Colors within this distance are considered equal
  # @method fuzz
  # @chainable
  # @param {Integer} distance distance in percentage
  ###
  fuzz: (distance) ->
    [ '-fuzz', distance ]
  ###*
  # Apply mathematical expression to an image channel(s)
  # @method fx
  # @chainable
  # @param {String} expression
  ###
  fx: (expression) ->
    [ '-fx', expression ]
  ###*
  # Level of gamma correction
  # @method gamma
  # @chainable
  # @param {Integer} value
  ###
  gamma: (value) ->
    [ '-gamma', value ]
  ###*
  # Reduce image noise and reduce detail levels
  # @method gaussianBlur
  # @chainable
  # @param {Object|String} geometry
  ###
  gaussianBlur: (geometry) ->
    [ '-gaussian-blur', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Preferred size or location of the image
  # @method geometry
  # @chainable
  # @param {Object|String} geometry
  ###
  geometry: (geometry) ->
    [ '-geometry', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Horizontal and vertical text placement
  # @method gravity
  # @chainable
  # @param {String} type
  ###
  gravity: (type) ->
    [ '-gravity', type ]
  ###*
  # Convert image to grayscale
  # @method grayscale
  # @chainable
  # @param {String} method
  ###
  grayscale: (method) ->
    [ '-grayscale', method ]
  ###*
  # Chromaticity green primary point
  # @method greenPrimary
  # @chainable
  # @param {String} point
  ###
  greenPrimary: (point) ->
    [ '-green-primary', point ]
  ###*
  # Print program options
  # @method help
  # @chainable
  ###
  help: ->
    [ '-help' ]
  ###*
  # Identify the format and characteristics of the image
  # @method identify
  # @chainable
  ###
  identify: ->
    [ '-identify' ]
  ###*
  # Implements the inverse discrete Fourier transform (DFT)
  # @method ift
  # @chainable
  ###
  ift: ->
    [ '-ift' ]
  ###*
  # Implode image pixels about the center
  # @method implode
  # @chainable
  # @param {Integer} amount
  ###
  implode: (amount) ->
    [ '-implode', amount ]
  ###*
  # Insert last image into the image sequence
  # @method insert
  # @chainable
  # @param {Integer} index
  ###
  insert: (index) ->
    [ '-insert', index ]
  ###*
  # Method to generate an intensity value from a pixel
  # @method intensity
  # @chainable
  # @param {String} method
  ###
  intensity: (method) ->
    [ '-intensity', method ]
  ###*
  # Type of rendering intent when managing the image color
  # @method intent
  # @chainable
  # @param {String} type
  ###
  intent: (type) ->
    [ '-intent', type ]
  ###*
  # Type of image interlacing scheme
  # @method interlace
  # @chainable
  # @param {String} type
  ###
  interlace: (type) ->
    [ '-interlace', type ]
  ###*
  # The space between two text lines
  # @method interlineSpacing
  # @chainable
  # @param {Integer} value
  ###
  interlineSpacing: (value) ->
    [ '-interline-spacing', value ]
  ###*
  # Pixel color interpolation method
  # @method interpolate
  # @chainable
  # @param {String} method
  ###
  interpolate: (method) ->
    [ '-interpolate', method ]
  ###*
  # The space between two words
  # @method interwordSpacing
  # @chainable
  # @param {Integer} value
  ###
  interwordSpacing: (value) ->
    [ '-interword-spacing', value ]
  ###*
  # The space between two characters
  # @method kerning
  # @chainable
  # @param {Integer} value
  ###
  kerning: (value) ->
    [ '-kerning', value ]
  ###*
  # Assign a label to an image
  # @method label
  # @chainable
  # @param {String} string
  ###
  label: (string) ->
    [ '-label', string ]
  ###*
  # Local adaptive thresholding
  # @method lat
  # @chainable
  # @param {Object|String} geometry
  ###
  lat: (geometry) ->
    [ '-lat', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Optimize or compare image layers
  # @method layers
  # @chainable
  # @param {String} method
  ###
  layers: (method) ->
    [ '-layers', method ]
  ###*
  # Adjust the level of image contrast
  # @method level
  # @chainable
  # @param {Integer} value
  ###
  level: (value) ->
    [ '-level', value ]
  ###*
  # Value pixel cache resource limit
  # @method limit
  # @chainable
  # @param {String} type
  ###
  limit: (type) ->
    [ '-limit', type ]
  ###*
  # Linear with saturation histogram stretch
  # @method linearStretch
  # @chainable
  # @param {Object|String} geometry
  ###
  linearStretch: (geometry) ->
    [ '-linear-stretch', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Rescale image with seam-carving
  # @method liquidRescale
  # @chainable
  # @param {Object|String} geometry
  ###
  liquidRescale: (geometry) ->
    [ '-liquid-rescale', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Format of debugging information
  # @method log
  # @chainable
  # @param {Integer} format
  ###
  log: (format) ->
    [ '-log', format ]
  ###*
  # Add Netscape loop extension to your GIF animation
  # @method loop
  # @chainable
  # @param {Integer} iterations
  ###
  loop: (iterations) ->
    [ '-loop', iterations ]
  ###*
  # Associate a mask with the image
  # @method mask
  # @chainable
  # @param {String} filename
  ###
  mask: (filename) ->
    [ '-mask', filename ]
  ###*
  # Frame color
  # @method mattecolor
  # @chainable
  # @param {String} color
  ###
  mattecolor: (color) ->
    [ '-mattecolor', color ]
  ###*
  # Apply a median filter to the image
  # @method median
  # @chainable
  # @param {Integer} radius
  ###
  median: (radius) ->
    [ '-median', radius ]
  ###*
  # Make each pixel the 'predominant color' of the neighborhood
  # @method mode
  # @chainable
  # @param {Integer} radius
  ###
  mode: (radius) ->
    [ '-mode', radius ]
  ###*
  # Vary the brightness, saturation, and hue
  # @method modulate
  # @chainable
  # @param {String} value
  ###
  modulate: (value) ->
    [ '-modulate', value ]
  ###*
  # Progress
  # @method monitor
  # @chainable
  # @param {String} monitor
  ###
  monitor: (monitor) ->
    [ '-monitor',  monitor ]
  ###*
  # Image to black and white
  # @method monochrome
  # @chainable
  # @param {String} transform
  ###
  monochrome: (transform) ->
    [ '-monochrome', transform ]
  ###*
  # Morph an image sequence
  # @method morph
  # @chainable
  # @param {Integer} value
  ###
  morph: (value) ->
    [ '-morph', value ]
  ###*
  # Kernel apply a morphology method to the image
  # @method morphology
  # @chainable
  # @param {String} method
  ###
  morphology: (method) ->
    [ '-morphology', method ]
  ###*
  # Simulate motion blur
  # @method motionBlur
  # @chainable
  # @param {Object|String} geometry
  ###
  motionBlur: (geometry) ->
    [ '-motion-blur', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Replace each pixel with its complementary color
  # @method negate
  # @chainable
  ###
  negate: ->
    [ '-negate' ]
  ###*
  # Add or reduce noise in an image
  # @method noise
  # @chainable
  # @param {Integer} radius
  ###
  noise: (radius) ->
    [ '-noise', radius ]
  ###*
  # Transform image to span the full range of colors
  # @method normalize
  # @chainable
  ###
  normalize: ->
    [ '-normalize' ]
  ###*
  # Change this color to the fill color
  # @method opaque
  # @chainable
  # @param {String} color
  ###
  opaque: (color) ->
    [ '-opaque', color ]
  ###*
  # Ordered dither the image
  # @method orderedDither
  # @chainable
  # @param {Integer} NxN
  ###
  orderedDither: (NxN) ->
    [ '-ordered-dither', NxN ]
  ###*
  # Image orientation
  # @method orient
  # @chainable
  # @param {String} type
  ###
  orient: (type) ->
    [ '-orient', type ]
  ###*
  # Size and location of an image canvas (setting)
  # @method page
  # @chainable
  # @param {Object|String} geometry
  ###
  page: (geometry) ->
    [ '-page', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Simulate an oil painting
  # @method paint
  # @chainable
  # @param {Integer} radius
  ###
  paint: (radius) ->
    [ '-paint', radius ]
  ###*
  # Set each pixel whose value is less than |epsilon| to -epsilon or epsilon (whichever is closer) otherwise the pixel value remains unchanged.
  # @method perceptible
  # @chainable
  ###
  perceptible: ->
    [ '-perceptible' ]
  ###*
  # Efficiently determine image attributes
  # @method ping
  # @chainable
  ###
  ping: ->
    [ '-ping' ]
  ###*
  # Font point size
  # @method pointsize
  # @chainable
  # @param {Integer} value
  ###
  pointsize: (value) ->
    [ '-pointsize', value ]
  ###*
  # Simulate a Polaroid picture
  # @method polaroid
  # @chainable
  # @param {Integer} angle
  ###
  polaroid: (angle) ->
    [ '-polaroid', angle ]
  ###*
  # Build a polynomial from the image sequence and the corresponding terms (coefficients and degree pairs).
  # @method poly
  # @chainable
  # @param {Integer} terms
  ###
  poly: (terms) ->
    [ '-poly', terms ]
  ###*
  # Reduce the image to a limited number of color levels
  # @method posterize
  # @chainable
  # @param {Integer} levels
  ###
  posterize: (levels) ->
    [ '-posterize', levels ]
  ###*
  # Set the maximum number of significant digits to be printed
  # @method precision
  # @chainable
  # @param {Integer} value
  ###
  precision: (value) ->
    [ '-precision', value ]
  ###*
  # Image preview type
  # @method preview
  # @chainable
  # @param {String} type
  ###
  preview: (type) ->
    [ '-preview', type ]
  ###*
  # Interpret string and print to console
  # @method print
  # @chainable
  # @param {String} string
  ###
  print: (string) ->
    [ '-print', string ]
  ###*
  # -filter process the image with a custom image filter
  # @method process
  # @chainable
  # @param {String} image
  ###
  process: (image) ->
    [ '-process', image ]
  ###*
  # Add, delete, or apply an image profile
  # @method profile
  # @chainable
  # @param {String} filename
  ###
  profile: (filename) ->
    [ '-profile', filename ]
  ###*
  # JPEG/MIFF/PNG compression level
  # @method quality
  # @chainable
  # @param {Integer} value
  ###
  quality: (value) ->
    [ '-quality', value ]
  ###*
  # Reduce image colors in this colorspace
  # @method quantize
  # @chainable
  # @param {String} colorspace
  ###
  quantize: (colorspace) ->
    [ '-quantize', colorspace ]
  ###*
  # Suppress all warning messages
  # @method quiet
  # @chainable
  ###
  quiet: ->
    [ '-quiet' ]
  ###*
  # Radial blur the image
  # @method radialBlur
  # @chainable
  # @param {Integer} angle
  ###
  radialBlur: (angle) ->
    [ '-radial-blur', angle ]
  ###*
  # Lighten/darken image edges to create a 3-D effect
  # @method raise
  # @chainable
  # @param {Integer} value
  ###
  raise: (value) ->
    [ '-raise', value ]
  ###*
  # Apply a random threshold to the image
  # @method randomThreshold
  # @chainable
  # @param {Integer} low
  ###
  randomThreshold: (low) ->
    [ '-random-threshold', low ]
  ###*
  # Set the red chromaticity primary point.
  # @method redPrimary
  # @chainable
  # @param {String} point
  ###
  redPrimary: (point) ->
    [ '-red-primary', point ]
  ###*
  # Pay attention to warning messages.
  # This option causes some warnings in some image formats to be treated as errors.
  # @method regardWarnings
  # @chainable
  ###
  regardWarnings: ->
    [ '-regard-warnings' ]
  ###*
  # Set a region in which subsequent operations apply.
  # @method region
  # @chainable
  # @param {Object|String} geometry
  ###
  region: (geometry) ->
    [ '-region', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Transform image colors to match this set of colors
  # @method remap
  # @chainable
  # @param {String} filename
  ###
  remap: (filename) ->
    [ '-remap', filename ]
  ###*
  # Render vector graphics
  # @method render
  # @chainable
  ###
  render: ->
    [ '-render' ]
  ###*
  # Size and location of an image canvas
  # @method repage
  # @chainable
  # @param {Object|String} geometry
  ###
  repage: (geometry) ->
    [ '-repage', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Change the resolution of an image
  # @method resample
  # @chainable
  # @param {Object|String} geometry
  ###
  resample: (geometry) ->
    [ '-resample', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Resize the image
  # @method resize
  # @chainable
  # @param {Object|String} geometry
  ###
  resize: (geometry) ->
    [ '-resize', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Settings remain in effect until parenthesis boundary.
  # @method respectParentheses
  # @chainable
  ###
  respectParentheses: ->
    [ '-respect-parentheses' ]
  ###*
  # Roll an image vertically or horizontally
  # @method roll
  # @chainable
  # @param {Object|String} geometry
  ###
  roll: (geometry) ->
    [ '-roll', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Apply Paeth rotation to the image
  # @method rotate
  # @chainable
  # @param {Integer} degrees
  ###
  rotate: (degrees) ->
    [ '-rotate', degrees ]
  ###*
  # Scale image with pixel sampling
  # @method sample
  # @chainable
  # @param {Object|String} geometry
  ###
  sample: (geometry) ->
    [ '-sample', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Horizontal and vertical sampling factor
  # @method samplingFactor
  # @chainable
  # @param {Object|String} geometry
  ###
  samplingFactor: (geometry) ->
    [ '-sampling-factor', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Scale the image
  # @method scale
  # @chainable
  # @param {Object|String} geometry
  ###
  scale: (geometry) ->
    [ '-scale', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Image scene number
  # @method scene
  # @chainable
  # @param {Integer} value
  ###
  scene: (value) ->
    [ '-scene', value ]
  ###*
  # Seed a new sequence of pseudo-random numbers
  # @method seed
  # @chainable
  # @param {Integer} value
  ###
  seed: (value) ->
    [ '-seed', value ]
  ###*
  # Segment an image
  # @method segment
  # @chainable
  # @param {Integer} values
  ###
  segment: (values) ->
    [ '-segment', values ]
  ###*
  # Selectively blur pixels within a contrast threshold
  # @method selectiveBlur
  # @chainable
  # @param {Object|String} geometry
  ###
  selectiveBlur: (geometry) ->
    [ '-selective-blur', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Separate an image channel into a grayscale image
  # @method separate
  # @chainable
  ###
  separate: ->
    [ '-separate' ]
  ###*
  # Simulate a sepia-toned photo
  # @method sepiaTone
  # @chainable
  # @param {Integer} threshold
  ###
  sepiaTone: (threshold) ->
    [ '-sepia-tone', threshold ]
  ###*
  # Value  set an image attribute
  # @method set
  # @chainable
  # @param {Integer} attribute
  ###
  set: (attribute) ->
    [ '-set', attribute ]
  ###*
  # Shade the image using a distant light source
  # @method shade
  # @chainable
  # @param {Integer} degrees
  ###
  shade: (degrees) ->
    [ '-shade', degrees ]
  ###*
  # Simulate an image shadow
  # @method shadow
  # @chainable
  # @param {Object|String} geometry
  ###
  shadow: (geometry) ->
    [ '-shadow', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Sharpen the image
  # @method sharpen
  # @chainable
  # @param {Object|String} geometry
  ###
  sharpen: (geometry) ->
    [ '-sharpen', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Shave pixels from the image edges
  # @method shave
  # @chainable
  # @param {Object|String} geometry
  ###
  shave: (geometry) ->
    [ '-shave', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Slide one edge of the image along the X or Y axis
  # @method shear
  # @chainable
  # @param {Object|String} geometry
  ###
  shear: (geometry) ->
    [ '-shear', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Increase the contrast without saturating highlights or shadows
  # @method sigmoidalContrast
  # @chainable
  # @param {Object|String} geometry
  ###
  sigmoidalContrast: (geometry) ->
    [ '-sigmoidal-contrast', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Smush an image sequence together
  # @method smush
  # @chainable
  # @param {Integer} offset
  ###
  smush: (offset) ->
    [ '-smush', offset ]
  ###*
  # Width and height of image
  # @method size
  # @chainable
  # @param {Object|String} geometry
  ###
  size: (geometry) ->
    [ '-size', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Simulate a pencil sketch
  # @method sketch
  # @chainable
  # @param {Object|String} geometry
  ###
  sketch: (geometry) ->
    [ '-sketch', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Negate all pixels above the threshold level
  # @method solarize
  # @chainable
  # @param {Integer} threshold
  ###
  solarize: (threshold) ->
    [ '-solarize', threshold ]
  ###*
  # Splice the background color into the image
  # @method splice
  # @chainable
  # @param {Object|String} geometry
  ###
  splice: (geometry) ->
    [ '-splice', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Displace image pixels by a random amount
  # @method spread
  # @chainable
  # @param {Integer} radius
  ###
  spread: (radius) ->
    [ '-spread', radius ]
  ###*
  # Geometry  replace each pixel with corresponding statistic from the neighborhood
  # @method statistic
  # @chainable
  # @param {String} type
  ###
  statistic: (type) ->
    [ '-statistic', type ]
  ###*
  # Strip image of all profiles and comments
  # @method strip
  # @chainable
  ###
  strip: ->
    [ '-strip' ]
  ###*
  # Graphic primitive stroke color
  # @method stroke
  # @chainable
  # @param {String} color
  ###
  stroke: (color) ->
    [ '-stroke', color ]
  ###*
  # Graphic primitive stroke width
  # @method strokewidth
  # @chainable
  # @param {Integer} value
  ###
  strokewidth: (value) ->
    [ '-strokewidth', value ]
  ###*
  # Render text with this font stretch
  # @method stretch
  # @chainable
  # @param {String} type
  ###
  stretch: (type) ->
    [ '-stretch', type ]
  ###*
  # Render text with this font style
  # @method style
  # @chainable
  # @param {String} type
  ###
  style: (type) ->
    [ '-style', type ]
  ###*
  # Swap two images in the image sequence
  # @method swap
  # @chainable
  # @param {Integer} indexes
  ###
  swap: (indexes) ->
    [ '-swap', indexes ]
  ###*
  # Swirl image pixels about the center
  # @method swirl
  # @chainable
  # @param {Integer} degrees
  ###
  swirl: (degrees) ->
    [ '-swirl', degrees ]
  ###*
  # Image to storage device
  # @method synchronize
  # @chainable
  # @param {Integer} synchronize
  ###
  synchronize: (synchronize) ->
    [ '-synchronize',  synchronize ]
  ###*
  # Mark the image as modified
  # @method taint
  # @chainable
  ###
  taint: ->
    [ '-taint' ]
  ###*
  # Name of texture to tile onto the image background
  # @method texture
  # @chainable
  # @param {String} filename
  ###
  texture: (filename) ->
    [ '-texture', filename ]
  ###*
  # Threshold the image
  # @method threshold
  # @chainable
  # @param {Integer} value
  ###
  threshold: (value) ->
    [ '-threshold', value ]
  ###*
  # Create a thumbnail of the image
  # @method thumbnail
  # @chainable
  # @param {Object|String} geometry
  ###
  thumbnail: (geometry) ->
    [ '-thumbnail', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Tile image when filling a graphic primitive
  # @method tile
  # @chainable
  # @param {String} filename
  ###
  tile: (filename) ->
    [ '-tile', filename ]
  ###*
  # Set the image tile offset
  # @method tileOffset
  # @chainable
  # @param {Object|String} geometry
  ###
  tileOffset: (geometry) ->
    [ '-tile-offset', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Tint the image with the fill color
  # @method tint
  # @chainable
  # @param {Integer} value
  ###
  tint: (value) ->
    [ '-tint', value ]
  ###*
  # Affine transform image
  # @method transform
  # @chainable
  ###
  transform: ->
    [ '-transform' ]
  ###*
  # Make this color transparent within the image
  # @method transparent
  # @chainable
  # @param {String} color
  ###
  transparent: (color) ->
    [ '-transparent', color ]
  ###*
  # Transparent color
  # @method transparentColor
  # @chainable
  # @param {String} color
  ###
  transparentColor: (color) ->
    [ '-transparent-color', color ]
  ###*
  # Flip image in the vertical direction and rotate 90 degrees
  # @method transpose
  # @chainable
  ###
  transpose: ->
    [ '-transpose' ]
  ###*
  # Flop image in the horizontal direction and rotate 270 degrees
  # @method transverse
  # @chainable
  ###
  transverse: ->
    [ '-transverse' ]
  ###*
  # Color tree depth
  # @method treedepth
  # @chainable
  # @param {Integer} value
  ###
  treedepth: (value) ->
    [ '-treedepth', value ]
  ###*
  # Trim image edges
  # @method trim
  # @chainable
  ###
  trim: ->
    [ '-trim' ]
  ###*
  # Image type
  # @method type
  # @chainable
  # @param {String} type
  ###
  type: (type) ->
    [ '-type', type ]
  ###*
  # Annotation bounding box color
  # @method undercolor
  # @chainable
  # @param {String} color
  ###
  undercolor: (color) ->
    [ '-undercolor', color ]
  ###*
  # Discard all but one of any pixel color.
  # @method uniqueColors
  # @chainable
  ###
  uniqueColors: ->
    [ '-unique-colors' ]
  ###*
  # The units of image resolution
  # @method units
  # @chainable
  # @param {String} type
  ###
  units: (type) ->
    [ '-units', type ]
  ###*
  # Sharpen the image
  # @method unsharp
  # @chainable
  # @param {Object|Number} options options `Object` for unsharpening or a `Number` sigma value (in which case defaults will be used for the remaining parameters).
  #   @param {Integer} [options.sigma=2] the
  #    standard deviation of the Gaussian, in pixels.
  #   @param {Integer} [options.radius=0]
  #     the radius of the Gaussian, in pixels,  not counting the center pixel.
  #   @param {Integer} [options.gain=1.0]
  #     the fraction of the difference between the original and the blur image that is added back into the original.
  #   @param {Integer} [options.threshold=0.05]
  #     the threshold, as a fraction of QuantumRange, needed to apply the difference amount.
  ###
  unsharp: (value) =>
    [ '-unsharp', "'#{INPUT_TYPES.unsharp value}'" ]
  ###*
  # Print detailed information about the image
  # @method verbose
  # @chainable
  ###
  verbose: ->
    [ '-verbose' ]
  ###*
  # Print version information
  # @method version
  # @chainable
  ###
  version: ->
    [ '-version' ]
  ###*
  # FlashPix viewing transforms
  # @method view
  # @chainable
  ###
  view: ->
    [ '-view' ]
  ###*
  # Soften the edges of the image in vignette style
  # @method vignette
  # @chainable
  # @param {Geometry} geometry
  ###
  vignette: (geometry) ->
    [ '-vignette', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Access method for pixels outside the boundaries of the image
  # @method virtualPixel
  # @chainable
  # @param {String} method
  ###
  virtualPixel: (method) ->
    [ '-virtual-pixel', method ]
  ###*
  # Alter an image along a sine wave
  # @method wave
  # @chainable
  # @param {Object|String} geometry
  ###
  wave: (geometry) ->
    [ '-wave', "'#{INPUT_TYPES.geometry geometry}'" ]
  ###*
  # Render text with this font weight
  # @method weight
  # @chainable
  # @param {String} type
  ###
  weight: (type) ->
    [ '-weight', type ]
  ###*
  # Chromaticity white point
  # @method whitePoint
  # @chainable
  # @param {String} point
  ###
  whitePoint: (point) ->
    [ '-white-point', point ]
  ###*
  # Force all pixels above the threshold into white
  # @method whiteThreshold
  # @chainable
  # @param {Integer} value
  ###
  whiteThreshold: (value) ->
    [ '-white-threshold', value ]
  ###*
  # Write images to this file
  # @method write
  # @chainable
  # @param {String} filename
  ###
  write: (filename) ->
    [ '-write', filename ]
  ###*
  # CUSTOM: Add custom arguments
  # @method add
  # @chainable
  ###
  add: ->
    arguments

###*
# Provides an `Object` that can handle ImageMagick options and run them through a given ImageMagick command.
#
# @class Command
# @constructor
# @private
# @protected
# @param {String} command the command to call when `Command.run` is executed.
# @param {Array} [argument_list] list of arguments to call. If given, `Command.run` will be called after the last argument has been called.
# @param {Function} [callback] function to call on completion of `Command.run`.
###
class Command extends EventEmitter

  constructor: (@command, argument_list, @callback) ->
    @arguments = []

    # Bind private methods to curent scope
    @addArgs           = => addArgs.apply @, arguments
    @optionToChainable = => optionToChainable.apply @, arguments
    @registerMethods   = => registerMethods.apply @, arguments
    @callMethods       = => callMethods.apply @, arguments

    # Add `options` functions to local methods
    @registerMethods()

    # If arguments were provided, use each object as the name of the option to call and its value as the arguments
    if argument_list?.length? and argument_list.length > 0
      @callMethods argument_list
      if @callback? and typeof @callback is 'function'
        @run @callback
    @


  ### Private methods (bound in constructor) ###

  ###*
  # Add the arguments given to the local `Array` of arguments.
  #
  # @method addArgs
  # @param [arguments]* arguments to add
  ###
  addArgs = (args...) ->
    @arguments = @arguments.concat args

  ###*
  # Bind the option `func` as a wrapped method on the current scope (`this`)..
  # If the wrapped method received a `Boolean` as argument, the resulting option string will have its first '-' replaced with a '+' (ImageMagick reset).
  #
  # @method optionToChainable
  # @param {String} option_name the name to use for the function to bind.
  # @param {Function} func the function that should be bound.
  ###
  optionToChainable = (option_name, func) ->
    @[option_name] = ((func) ->
      ->
        # Add argument as a reset switch if the only argument is a Boolean
        if arguments.length? and arguments.length is 1 and typeof arguments[0] is 'boolean'
          args = (func.call @, '').slice 0, 1
          if args.length and args.length > 0
            args[0] = args[0].replace /^-/, '+'
          @addArgs args...
        # Else add normally
        else
          @addArgs (func.apply @, arguments)...
        # Return `this` so the method is chainable
        @
    ).call this, func

  ###*
  # Bind all options defined in OPTIONS to the current scope (`this`)
  #
  # @method registerMethods
  # @uses optionToChainable
  ###
  registerMethods = ->
    for option, func of OPTIONS
      @optionToChainable option, func
    null

  ###*
  # Call each argument in the argument_list.
  # Each item in the argument_list can be either an `Object` or a `String`.
  # If it is an `Object`, each property name will be used as the option name and its property value will be used as the argument for that option.
  # If it is a `String`, the option of that name will be called without arguments.
  #
  # @method callMethods
  # @param {Array} argument_list list of arguments to call in order
  ###
  callMethods = (argument_list) ->
    for arg in argument_list
      if typeof arg is 'object'
        for option, args of arg
          throw new Error "No such option `#{option}`"  if not @[option]?
          @[option] args
      else if typeof arg is 'string'
        throw new Error "No such option `#{arg}`"  if not @[arg]?
        @[arg]()
      else
        throw new Error "Unsupported argument type `#{typeof arg}` of argument `#{arg}`"


  ### Public methods ###

  ###*
  # Run command.
  #
  # @method run
  # @param {Function} callback function to call on completion. If not defined, 'done' and 'run_success' or 'run_error' will be emitted on completion.
  # @chainable
  ###
  run: (callback) =>
    ChildProcess.exec "convert #{@arguments.join ' '}", (error, stderr, stdout) =>
      if callback
        callback error, stdout, stderr
      else
        @emit 'done', error, stdout, stderr
        return @emit 'run_error', error  if error
        return @emit 'run_success', stdout
    @


module.exports =
  inputTypes : INPUT_TYPES
  options    : OPTIONS
  ###*
  # Convert between image formats as well as resize an image, blur, crop, despeckle, dither, draw on, flip, join, re-sample, and much more.
  #
  # @method convert
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  convert: ->
    new Command 'convert', arguments...

  ###*
  # Describes the format and characteristics of one or more image files.
  #
  # @method identify
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  identify: ->
    new Command 'identify', arguments...

  ###*
  # Resize an image, blur, crop, despeckle, dither, draw on, flip, join, re-sample, and much more. Mogrify overwrites the original image file, whereas,  convert writes to a different image file.
  #
  # @method mogrify
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  mogrify: ->
    new Command 'mogrify', arguments...

  ###*
  # Overlaps one image over another.
  #
  # @method composite
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  composite: ->
    new Command 'composite', arguments...

  ###*
  # Create a composite image by combining several separate images. The images are tiled on the composite image optionally adorned with a border, frame, image name, and more.
  #
  # @method montage
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  montage: ->
    new Command 'montage', arguments...

  ###*
  # Mathematically and visually annotate the difference between an image and its reconstruction..
  #
  # @method compare
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  compare: ->
    new Command 'compare', arguments...

  ###*
  # A lightweight tool to stream one or more pixel components of the image or portion of the image to your choice of storage formats.
  # It writes the  pixel components as they are read from the input image a row at a time making stream desirable when working with large images or when you require raw pixel components.
  #
  # @method stream
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  stream: ->
    new Command 'stream', arguments...

  ###*
  # Displays an image or image sequence on any X server.
  #
  # @method display
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  display: ->
    new Command 'display', arguments...

  ###*
  # Animates an image sequence on any X server.
  #
  # @method animate
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  animate: ->
    new Command 'animate', arguments...

  ###*
  # Saves any visible window on an X server and outputs it as an image file.
  # You can capture a single window, the entire screen, or any  rectangular  portion of the screen.
  #
  # @method import
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  import: ->
    new Command 'import', arguments...

  ###*
  # Interprets and executes scripts written in the Magick Scripting Language (MSL).
  #
  # @method conjure
  # @for ImageMagick
  # @extends Command
  # @param {Array} [argument_list] list of arguments to call. If given, `run` will be called after the last argument has been called.
  # @param {Function} [callback] function to call on completion of `run`.
  # @return {Command} a `Command` instance.
  ###
  conjure: ->
    new Command 'conjure', arguments...