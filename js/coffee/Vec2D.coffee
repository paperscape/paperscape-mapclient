# VEC2D module
# 
# A simple two-dimensional vector for convenience

define () ->

    # Simple 2D vector class (extend as needed)
    class Vec2D
        constructor: (x, y) ->
            @x = x
            @y = y

        copy:    -> new Vec2D(@x, @y)
        
        add: (v) -> new Vec2D(@x + v.x, @y + v.y)
        
        sub: (v) -> new Vec2D(@x - v.x, @y - v.y)
        
        mul: (c) -> new Vec2D(@x * c  , @y * c  )
        
        scale: (cx,cy) -> new Vec2D(@x * cx  , @y * cy )

        round:   -> new Vec2D(Math.round(@x) , Math.round(@y))

        floor:   -> new Vec2D(Math.floor(@x) , Math.floor(@y))

        ceil :   -> new Vec2D(Math.ceil(@x) , Math.ceil(@y))

        len:     -> Math.sqrt(@x*@x + @y*@y)

    return Vec2D
