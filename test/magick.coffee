chai = require 'chai'
chai.should()  # add `should` to the Object prototype
expect = chai.expect

mockery = require 'mockery'
sinon   = require 'sinon'


describe "magick.js", ->

  describe 'Options parsing', ->
    describe 'Geometry', ->
      testWidth = 20
      testHeight = 30
      testFloat = 0.4

      Magick = require '../src/magick'

      ### Positive tests ###

      it "should understand `opacity`", ->
        geometry = Magick.inputTypes.geometry opacity: testHeight
        geometry.should.equal "#{testHeight}"

      it "should understand `opacity` and `sigma`", ->
        geometry = Magick.inputTypes.geometry opacity: testHeight, sigma: testFloat
        geometry.should.equal "#{testHeight}x#{testFloat}"

      it "should understand `scale`", ->
        geometry = Magick.inputTypes.geometry scale: testWidth
        geometry.should.equal "#{testWidth}%"

      it "should understand `area`", ->
        geometry = Magick.inputTypes.geometry area: testWidth
        geometry.should.equal "#{testWidth}@"

      it "should understand `scaleWidth` and `scaleHeight`", ->
        geometry = Magick.inputTypes.geometry scaleWidth: testWidth, scaleHeight: testHeight
        geometry.should.equal "#{testWidth}%x#{testHeight}%"

      it "should understand `width` as only argument", ->
        geometry = Magick.inputTypes.geometry width: testWidth
        geometry.should.equal "#{testWidth}"

      it "should understand `height` as only argument", ->
        geometry = Magick.inputTypes.geometry height: testWidth
        geometry.should.equal "x#{testWidth}"

      it "should understand a false `preserveAspect` when given `width` and `height`", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight, preserveAspect: false
        geometry.should.equal "#{testWidth}x#{testHeight}!"

      it "should understand `width` and `height`", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight
        geometry.should.equal "#{testWidth}x#{testHeight}"

      it "should understand `width` and `height` width `onlyShrink`", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight, onlyShrink: true
        geometry.should.equal "#{testWidth}x#{testHeight}>"

      it "should understand `width` and `height` width `onlyEnlarge`", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight, onlyEnlarge: true
        geometry.should.equal "#{testWidth}x#{testHeight}<"

      it "should understand `width` and `height` width `fill`", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight, fill: true
        geometry.should.equal "#{testWidth}x#{testHeight}^"

      it "should understand and append offsets", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight, fill: true, offsetX: testHeight, offsetY: testWidth
        geometry.should.equal "#{testWidth}x#{testHeight}^+#{testHeight}+#{testWidth}"

      it "should understand and append negative offsets", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight, fill: true, offsetX: testHeight, offsetY: (testWidth*-1)
        geometry.should.equal "#{testWidth}x#{testHeight}^+#{testHeight}-#{testWidth}"

      it "should understand offsets with `usePercentage`", ->
        geometry = Magick.inputTypes.geometry width: testWidth, height: testHeight, fill: true, offsetX: testHeight, offsetY: testWidth, usePercentage: true
        geometry.should.equal "#{testWidth}x#{testHeight}^+#{testHeight}+#{testWidth}%"

      it "should pass through String values", ->
        geometry = Magick.inputTypes.geometry "#{testWidth}x#{testHeight}^+#{testHeight}+#{testWidth}%"
        geometry.should.equal "#{testWidth}x#{testHeight}^+#{testHeight}+#{testWidth}%"

      ### Negative tests ###

      it "if argument is not understood and is an Object, should thow error", ->
        geometryCall = -> Magick.inputTypes.geometry wrongParameter: testWidth
        expect(geometryCall).to.throw Error, "`wrongParameter` is not an accepted option"

      it "if argument is not understood and is not an Object, should pass it through a string", ->
        geometry = Magick.inputTypes.geometry testWidth
        geometry.should.equal "#{testWidth}"

    describe 'Define', ->
      Magick = require '../src/magick'
      it "should understand a `size` subkey", ->
        definitions = Magick.inputTypes.define jpeg:(size:width:128,height:128), showkernel:1
        definitions.should.be.an 'array'
        definitions.should.have.length 2
        definitions.should.include "jpeg:size=128x128"
        definitions.should.include "showkernel=1"

  describe "Function calling", ->
    Magick = null
    eventsMock = null

    beforeEach ->
      mockery.enable useCleanCache: true

      mockery.registerMock 'child_process',
        exec: (args, callback) ->
          callback null, args, ''

      eventsMock =
        emitSpy: sinon.spy()
      eventsMock.EventEmitter = class EventEmitter
          emit: eventsMock.emitSpy

      mockery.registerMock 'events', eventsMock

      mockery.registerAllowable '../src/magick'

      Magick = require '../src/magick'

    afterEach ->
      mockery.deregisterAll()
      mockery.disable()

    ### Positive tests ###

    it "should accept programmatic argument adding", ->
      convert = Magick.convert()
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

    it "should accept initial arguments", (done) ->
      convert = Magick.convert [
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
      ], done
      convert.arguments.should.be.an 'array'
      convert.arguments.join(' ').should.eql "-define 'jpeg:size=256x256' image.png -auto-orient -fuzz 5 -trim +repage -strip -thumbnail '128x128>' -unsharp '0x0.5+1+0.05' PNG8:image_thumb.png"

    it "should emit events on completion if no callback was given", ->
      convert = Magick.convert [
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
      ]
      eventsMock.emitSpy.called.should.be.true
      # Note that these event arguments are from the mocked child_process, so do not represent actual output
      eventsMock.emitSpy.args.should.eql [
        ["done", null, "", "convert -define 'jpeg:size=256x256' image.png -auto-orient -fuzz 5 -trim +repage -strip -thumbnail '128x128>' -unsharp '0x0.5+1+0.05' PNG8:image_thumb.png"]
        ["run_success", ""]
      ]

    ### Negative tests ###

    it "if argument is not understood, should thow error", ->
      call = -> Magick.convert [42:null]
      expect(call).to.throw Error, "No such option `#{42}`"

    it "if argument is not understood and is an Object or String, should thow error", ->
      call = -> Magick.convert [(->)]
      expect(call).to.throw Error, "Unsupported argument type `function` of argument `#{(->)}`"
