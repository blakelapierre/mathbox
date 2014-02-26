Geometry = require('./geometry')

class LineGeometry extends Geometry

  shaderAttributes: () ->
    line:
      type: 'v2'
      value: null

  constructor: (options) ->
    THREE.BufferGeometry.call @

    samples  = +options.samples || 2
    strips   = +options.strips  || 1
    ribbons  = +options.ribbons || 1
    segments = samples - 1

    points    = samples      * strips * ribbons
    triangles = segments * 2 * strips * ribbons

    @addAttribute 'index',    Uint16Array,  triangles * 3, 1
    @addAttribute 'position', Float32Array, points,        3
    @addAttribute 'line',     Float32Array, points,        2

    index    = @_emitter 'index'
    position = @_emitter 'position'
    line     = @_emitter 'line'

    base = 0
    for i in [0...ribbons]
      for j in [0...strips]
        for k in [0...samples - 1]
          index base
          index base + 1
          index base + 2

          index base + 2
          index base + 1
          index base + 3
        base += 2
      base += 2

    for i in [0...ribbons]
      y = 0

      for j in [0...strips]
        x = 0

        for k in [0...samples]
          edge = if k == 0 then -1 else if k == segments then 1 else 0

          position x, y, 0
          position x, y, 0

          line edge, 1
          line edge, -1

          x++
        #
      y++

    return

module.exports = LineGeometry