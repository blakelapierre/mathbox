View = require './view'
Util = require '../../../util'

class Polar extends View
  @traits: ['node', 'object', 'view', 'polar']

  make: () ->
    super

    types = @_attributes.types
    @uniforms =
      polarBend:   @node.attributes['polar.bend']
      polarHelix:  @node.attributes['polar.helix']
      polarFocus:  @_attributes.make types.number()
      polarAspect: @_attributes.make types.number()
      viewMatrix:  @_attributes.make types.mat4()

    @viewMatrix          = @uniforms.viewMatrix.value
    @objectMatrix        = new THREE.Matrix4()

    @aspect = 1

  unmake: () ->
    super

    delete @viewMatrix
    delete @objectMatrix

  change: (changed, touched, init) ->

    return unless touched['object'] or touched['view'] or touched['polar'] or init

    @helix = helix = @_get 'polar.helix'
    @bend  = bend  = @_get 'polar.bend'

    @focus = focus = if bend > 0 then 1 / bend - 1 else 0

    o = @_get 'object.position'
    s = @_get 'object.scale'
    q = @_get 'object.rotation'
    r = @_get 'view.range'

    x = r[0].x
    y = r[1].x
    z = r[2].x
    dx = (r[0].y - x) || 1
    dy = (r[1].y - y) || 1
    dz = (r[2].y - z) || 1
    sx = s.x
    sy = s.y
    sz = s.z

    # Watch for negative scales.
    idx = if dx > 0 then 1 else -1

    # Recenter viewport on origin the more it's bent
    [y, dy] = Util.Axis.recenterAxis y, dy, bend

    # Adjust viewport range for polar transform.
    # As the viewport goes polar, the X-range is interpolated to the Y-range instead,
    # creating a perfectly circular viewport.
    ady = Math.abs dy
    fdx = dx + (ady * idx - dx) * bend
    sdx = fdx / sx
    sdy = dy  / sy
    @aspect = aspect = Math.abs (sdx / sdy)

    @uniforms.polarFocus.value  = focus
    @uniforms.polarAspect.value = aspect

    # Forward transform
    @viewMatrix.set(
      2/fdx, 0, 0, -(2*x+dx)/dx,
      0, 2/dy, 0,  -(2*y+dy)/dy,
      0, 0, 2/dz,  -(2*z+dz)/dz,
      0, 0, 0, 1 #,
    )
    @objectMatrix.compose o, q, s
    @viewMatrix.multiplyMatrices @objectMatrix, @viewMatrix

    if changed['view.range'] or touched['polar']
      @trigger
        type: 'range'

  to: (vector) ->
    if @bend > 0.0001
      radius = @focus + vector.y * aspect
      x      = vector.x * @bend

      # Separate folds of complex plane into helix
      vector.z += vector.x * @helix * @bend

      # Apply polar warp
      vector.x = Math.sin(x) * radius
      vector.y = (Math.cos(x) * radius - focus) / aspect

    vector.applyMatrix4 @viewMatrix

  transform: (shader) ->
    shader.pipe 'polar.position', @uniforms
    @parent?.transform shader

  axis: (dimension) ->
    range = @_get('view.range')[dimension - 1]
    min = range.x
    max = range.y

    # Correct Y extents during polar warp.
    if dimension == 2 && @bend > 0
      max = Math.max Math.abs(max), Math.abs(min)
      min = Math.max -@focus / @aspect + .001, min

    return new THREE.Vector2 min, max

  ###
  from: (vector) ->
    this.inverse.multiplyVector3(vector);
  },
  ###

module.exports = Polar
