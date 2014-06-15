Transform = require './transform'
Util      = require '../../../util'

class Swizzle extends Transform
  @traits: ['node', 'bind', 'transform', 'swizzle']

  shader: (shader) ->
    @bind.source.shader shader
    shader.call @swizzler if @swizzler

  make: () ->
    super

    # Swizzling order
    order = @_get 'swizzle.order'
    @swizzler = Util.GLSL.swizzleVec4 order if order != 'xyzw'

    # Notify of reallocation
    @trigger
      event: 'rebuild'

  unmake: () ->
    super
    @swizzler = null

  change: (changed, touched, init) ->
    @rebuild() if touched['swizzle']


module.exports = Swizzle
