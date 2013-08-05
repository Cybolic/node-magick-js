# node-imagemagick

[![Build Status](https://travis-ci.org/Cybolic/node-imagemagick.png?branch=master)](https://travis-ci.org/Cybolic/node-imagemagick)

A Node.js interface to the ImageMagick command-line tools.

NOTE: This project does not yet support all of ImageMagicks tools. Currently only `convert` is supported.

## Examples

To save a thumbnail of an image:
```javascript
imagemagick = require('imagemagick');

/* Run the command immediately: */
imagemagick.convert(
  {define: {jpeg:{size:{width:256, height:256}}},  // `define` definitions are serialised and `geometry` values are parsed.
  {add: 'image.png'},                              // `add` is a way to add custom arguments, in this case the filename.
  'autoOrient',                                    // options that don't require arguments can be given as a string or object (e.g. `{autoOrient: null}`).
  {fuzz:5},
  'trim',
  {repage: true},                                  // if a Boolean is given as the only argument, then the option functions as a reset (e.g. '+repage').
  {unsharp: 0.5},                                  // `unsharp` accepts either a sigma value or an object as an argument (e.g. `{unsharp: {sigma:6, gain:0.5, threshold:0}}`).
  {add: 'PNG8:image_thumb.png'},
  function(error, stdout, stderr) {                // any argument that is a Function will be used as the callback.
    console.log "Thumbnail created."               // If you prefer events, 'run_error' or 'run_success' will be emitted if not callback function is given.
  }
);

/* Or create it programmatically: */
var cropImage = true;
var convert = imagemagick.convert()
  .define({jpeg:{size:{width:256, height:256}}})
  .add('image.png'})
  .autoOrient')
;
if (cropImage) {
  convert.fuzz(5)
    .trim()
    .repage(true)
  ;
}
convert
  .unsharp(0.5)
  .add('PNG8:image_thumb.png')
;
convert.on('run_success', function(stdout) {
    console.log "Thumbnail created."
});
convert.run();
```

