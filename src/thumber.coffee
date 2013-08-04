child_process = require 'child_process'
path          = require 'path'
fs            = require 'fs'

config =
  # This string will be removed from the beginning of the names of thumbnails
  baseDir : path.normalize "#{__dirname}/../../"   # assuming this file is in project_dir/node_modules/thumber/
  # This is where thumbnails will be placed
  thumbDir: path.normalize "/tmp/node-thumbs/"

  defaults:
    maxWidth       : 800
    maxHeight      : 90
    autoRotate     : true     # Rotate based on metadata
    autoCrop       : true
    stripMetaData  : true
    sharpen        : 0.5      # ImageMagicks resize method is slighly blurry, so sharpen a bit
    quality        : 85       # Recommended standards suggest 95, but Google Print uses 85 and it seems perfectly fine
    fontBackground : 'white'
    fontColor      : 'black'
    fontText       : "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz\\n0123456789.:,;'\"'\"'\"[!?]+-*/="

  getOutputArguments: (inputPath) ->
    args = []
    # Strip colour profiles and other info
    args.push "-strip"  if config.settings.stripMetaData
    # Strip general info, resize (only shrink) and optimise for thumbnails
    args.push "-thumbnail", "'#{config.settings.maxWidth}x#{config.settings.maxHeight}>'"
    args


  defaultArguments:
    output: (settings) ->  # No outputPath, since this is general options for all types, not the actual full argument list
     [
        "-strip"  if settings.stripMetaData                            # Strip colour profiles and other info
        "-thumbnail", "'#{settings.maxWidth}x#{settings.maxHeight}>'"  # Strip general info, resize (only shrink) and optimise for thumbnails
        "-quality", "#{settings.quality}"
     ]

  fileTypes:

    bitmap:
      regex: new RegExp '\.('+
          'jpg|jpeg|png|gif|tiff|tga|jp2|jpc|jng|pgx|kdx|jpx|mac|k25|kdc|mat|'+
          'miff|mng|mrw|dpx|bmp|arw|cur|dcm|ico|icon|dcr|dcx|hdr|nef|nrw|orf|'+
          'pbm|pcd|pct|pnm|ppm|raf|sgi|tim|vda|vst|xbm|xpm'+
        ')$', 'i'
      arguments:
        input: (settings, inputPath) ->
          [
            "-define", "jpeg:size=#{settings.maxWidth*2}x#{settings.maxHeight*2}"  # Don't read JPEGs as bigger than twice the output size. Saves memory
            "'#{inputPath}[0]'"
          ]
        process: (settings) ->
          [
            "-auto-orient"  if settings.autoRotate  # Rotate image according to their meta data
            "-fuzz", "5%"   if settings.autoCrop    # Regard colours as being the same within this percentage
            "-trim"         if settings.autoCrop    # Auto-crop the image to remove blank edges (hence the 'fuzz')
            "+repage"       if settings.autoCrop    # Reset the canvas size following the trim operation
          ]
        output: (settings, outputPath) ->
          config.fileTypes.all.arguments.output().concat [
            "-unsharp", "0x#{settings.sharpen}"  if settings.sharpen isnt false  # ImageMagicks resize method is slighly blurry, so sharpen a bit
            "'#{outputPath}'"
          ]

    vector:
      regex: new RegExp '\.('+
          'ai|art|epi|eps|mvg|pdf|ps|txt'+
        ')$', 'i'
      arguments:
        input: (settings, inputPath) ->
          [
            "-density", "96"
            "'#{inputPath}[0]'"
          ]
        process: (settings)              -> config.fileTypes.bitmap.arguments.process settings
        output : (settings, outputPath) -> config.fileTypes.bitmap.arguments.output settings, outputPath

    font:
      regex: new RegExp '\.('+
          'otf|ttf|woff|eot|svgt'+
        ')$', 'i'
      arguments:
        input: (settings, inputPath) ->
          [
            "-font", "'#{inputPath}'"
          ]
        process: (settings) ->
          [
            "-background", "#{settings.fontBackground}"
            "-fill"      , "#{settings.fontColor}"
            "-pointsize" , "#{settings.maxHeight}"
            # "pango:'#{settings.fontText}'"  # Pango doesn't currently use antialiasing, so use the `label` argument instead
            "-antialias"
            "label:'#{settings.fontText}'"
          ]
        output: (settings, outputPath) ->
          config.defaultArguments.output().concat [
            "-colors", "256"
            "'PNG8:#{@outputPath}'"
          ]


clearSettings = exports.clearSettings = ->
  config.settings = config.defaults

clearSettings()

setBaseDir = (baseDir, callback) ->
  fs.stat baseDir, (error, stats) ->
    return callback "baseDir is not a directory"  unless stats.isDirectory()
    config.baseDir = baseDir

setThumbDir = (thumbDir, callback) ->
  fs.stat thumbDir, (error, stats) ->
    return callback "thumbDir is not a directory"  unless stats.isDirectory()
    config.thumbDir = thumbDir


getSettings = (settings = {}) ->
  # Make sure all default settings exist in our settings object
  settings[key] ?= config.defaults[key] for key of config.defaults

  # Make sure integer values are set as such
  for key in ['maxWidth', 'maxHeight', 'quality']
    settings[key] = config.defaults[key]  unless (typeof settings[key] is 'number')
  # `sharpen` can also be `false`, so check that seperately
  settings['sharpen'] = config.defaults['sharpen']  unless settings['sharpen'] is false or (typeof settings['sharpen'] is 'number')

  settings


getFileType = (inputPath) ->
  for key, value of config.fileTypes
    if value.regex.test inputPath
      return value
  null


getArguments = (fileType, inputPath, outputPath, settings) ->
  # Create the argument list
  args = []
  args.concat fileType.arguments.input settings, inputPath
  args.concat fileType.arguments.process settings
  args.concat fileType.arguments.output settings, outputPath
  # Filter it for `undefined` values
  args.filter (value) -> value isnt undefined
  args


runConvert = (args, callback) ->
  child_process.exec "convert #{args.join ' '}", callback


copyTimeStamps = (srcPath, destPath, callback) ->
  fs.stat srcPath, (error, stats) ->
    return callback error  if error
    fs.utimes destPath, stats.atime, stats.mtime, callback


generateThumbnail = (inputPath, outputPath, settings, callback) ->
  settings = getSettings settings

  fileType = getFileType inputPath
  # Return now if we can't handle this file type
  callback 'Unsupported file type', null  if fileType is null

  # Do the conversion
  runConvert (getArguments fileType, inputPath, outputPath, settings), (error, stderr, stdout) ->
    if error
      return callback error  if callback?
      return error

    copyTimeStamps inputPath, outputPath, (error) ->
      callback error, outputPath  if callback?


getThumbnail = (inputPath, settings, callback) ->
  settings ?= {}

  fs.stat inputPath, (error, stats) ->
    return callback "File doesn't exist or cannot be read."  if error

    thumbPath = "#{config.thumbDir}/#{encodeURIComponent inputPath.replace config.baseDir, ''}.png"

    # Check if a thumbnail already exists and matches the modification date of the source
    fs.stat thumbPath, (error, thumb_stats) ->
      # If thumbnail doesn't exist or is out of date
      if error or "#{stats.mtime}" isnt "#{thumb_stats.mtime}"
        generateThumbnail inputPath, thumbPath, settings, callback
      else
        # A thumbnail already exists and is up to date, return that
        callback null, thumbPath


module.exports =
  runConvert        : runConvert
  copyTimeStamps    : copyTimeStamps
  generateThumbnail : generateThumbnail
  getThumbnail      : getThumbnail