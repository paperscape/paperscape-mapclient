define ['app/Vec2D'], (Vec2D) ->
    run : ->
        module "Vec2D"

        v1 = new Vec2D(3,4.5)
        v2 = new Vec2D(9,-6)
        v3 = new Vec2D(-3.456,+9.9)
        v4 = new Vec2D(3,4)

        test "Arithmetic", ->
            vRes = v1.add(v2)
            equal vRes.x, 12, 
                "add: v1.x + v2.x = v3.x"
            equal vRes.y, -1.5, 
                "add: v1.y + v2.y = v3.y"
            deepEqual vRes,new Vec2D(12,-1.5), 
                "add: v1 + v2 = v3"
            vRes = v1.sub(v2)
            equal vRes.x, -6, 
                "sub: v1.x - v2.x = v3.x"
            equal vRes.y, 10.5, 
                "sub: v1.y - v2.y = v3.y"
            deepEqual vRes,new Vec2D(-6,10.5), 
                "sub: v1 - v2 = v3"
            vRes = v1.mul(10)
            equal vRes.x, 30, 
                "mul: v1.x * k = v2.x"
            equal vRes.y, 45, 
                "mul: v1.y * k = v2.y"
            deepEqual vRes, new Vec2D(30,45), 
                "mul: v1 *k = v2"
            vScale = v1.scale(4,-2)
            equal vScale.x, 12, 
                "scale: v1.x * kx = v2.x"
            equal vScale.y, -9, 
                "scale: v1.y * ky = v2.y"
            deepEqual vScale, new Vec2D(12,-9), 
                "scale: v1 * (kx,ky) = v2"
            vRound = v3.round()
            equal vRound.x, -3, 
                "round x component"
            equal vRound.y, 10, 
                "round y component"
            deepEqual vRound, new Vec2D(-3,10), 
                "round"
            vLen  = v4.len()
            equal vLen,5, 
                "length"
