chai = require 'chai'
chai.should()  # add `should` to the Object prototype
expect = chai.expect


describe "ImageMagick", ->

  describe 'Options parsing', ->
    describe 'Geometry', ->
      testWidth = 20
      testHeight = 30
      ImageMagick = require '../src/imagemagick'

      ### Positive tests ###

      it "should understand `scale`", ->
        geometry = ImageMagick.inputTypes.geometry scale: testWidth
        geometry.should.equal "#{testWidth}%"

      it "should understand `area`", ->
        geometry = ImageMagick.inputTypes.geometry area: testWidth
        geometry.should.equal "#{testWidth}@"

      it "should understand `scaleWidth` and `scaleHeight`", ->
        geometry = ImageMagick.inputTypes.geometry scaleWidth: testWidth, scaleHeight: testHeight
        geometry.should.equal "#{testWidth}%x#{testHeight}%"

      it "should understand `width` as only argument", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth
        geometry.should.equal "#{testWidth}"

      it "should understand `height` as only argument", ->
        geometry = ImageMagick.inputTypes.geometry height: testWidth
        geometry.should.equal "x#{testWidth}"

      it "should understand a false `preserveAspect` when given `width` and `height`", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth, height: testHeight, preserveAspect: false
        geometry.should.equal "#{testWidth}x#{testHeight}!"

      it "should understand `width` and `height`", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth, height: testHeight
        geometry.should.equal "#{testWidth}x#{testHeight}"

      it "should understand `width` and `height` width `onlyShrink`", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth, height: testHeight, onlyShrink: true
        geometry.should.equal "#{testWidth}x#{testHeight}>"

      it "should understand `width` and `height` width `onlyEnlarge`", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth, height: testHeight, onlyEnlarge: true
        geometry.should.equal "#{testWidth}x#{testHeight}<"

      it "should understand `width` and `height` width `fill`", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth, height: testHeight, fill: true
        geometry.should.equal "#{testWidth}x#{testHeight}^"

      it "should understand and append offsets", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth, height: testHeight, fill: true, offsetX: testHeight, offsetY: testWidth
        geometry.should.equal "#{testWidth}x#{testHeight}^+#{testHeight}+#{testWidth}"

      it "should understand and append negative offsets", ->
        geometry = ImageMagick.inputTypes.geometry width: testWidth, height: testHeight, fill: true, offsetX: testHeight, offsetY: (testWidth*-1)
        geometry.should.equal "#{testWidth}x#{testHeight}^+#{testHeight}-#{testWidth}"

      ### Negative tests ###

      it "if argument is not understood and is an Object, should thow error", ->
        error = ''
        try
          geometry = ImageMagick.inputTypes.geometry wrongParameter: testWidth
        catch e
          error = e.message
        error.should.equal "`wrongParameter` is not an accepted option"

      it "if argument is not understood and is not an Object, should pass it through a string", ->
        geometry = ImageMagick.inputTypes.geometry testWidth
        geometry.should.equal "#{testWidth}"

    describe 'Define', ->
      ImageMagick = require '../src/imagemagick'
      it "should understand a `size` subkey", ->
        definitions = ImageMagick.inputTypes.define jpeg:(size:width:128,height:128), showkernel:1
        definitions.should.be.an 'array'
        definitions.should.have.length 2
        definitions.should.include "jpeg:size=128x128"
        definitions.should.include "showkernel=1"

  describe "Function calling", ->
    ImageMagick = require '../src/imagemagick'
    ImageMagick.convert::run = ->
      @

    it "should accept initial arguments", ->
      convert = ImageMagick.convert(
        {define: jpeg: size: width:256, height:256}
        {add: 'image.png'}
        'autoOrient'
        {fuzz: 5}
        'trim'
        {repage: true}
        'strip'
        {thumbnail: width:128, height:128, onlyShrink:true}
        {unsharp: 0.5}
        {add: 'PNG8:image_thumb.png'}
        (error, stdout, stderr) ->
          console.log "Thumbnail created."
      )
      convert.arguments.should.be.an 'array'
      convert.arguments.join(' ').should.eql "-define 'jpeg:size=256x256' image.png -auto-orient -fuzz 5 -trim +repage -strip -thumbnail '128x128>' -unsharp '0x0.5+1+0.05' PNG8:image_thumb.png"

    it "should accept programmatic argument adding", ->
      convert = ImageMagick.convert()
      convert.define jpeg: size: width:256, height:256
      convert.add 'image.png'
      convert.autoOrient()
      convert.fuzz 5
      convert.trim()
      convert.repage true
      convert.strip()
      convert.thumbnail width:128, height:128, onlyShrink:true
      convert.unsharp 0.5
      convert.add 'PNG8:image_thumb.png'
      convert.arguments.should.be.an 'array'
      convert.arguments.join(' ').should.eql "-define 'jpeg:size=256x256' image.png -auto-orient -fuzz 5 -trim +repage -strip -thumbnail '128x128>' -unsharp '0x0.5+1+0.05' PNG8:image_thumb.png"
