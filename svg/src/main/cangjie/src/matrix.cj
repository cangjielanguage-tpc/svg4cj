/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

public class Matrix2 {
    var a: Float64
    var b: Float64
    var c: Float64
    var d: Float64
    var tx: Float64
    var ty: Float64

    init(a: Float64, b: Float64, c: Float64, d: Float64, tx: Float64, ty: Float64) {
        this.a = a
        this.b = b
        this.c = c
        this.d = d
        this.tx = tx
        this.ty = ty
    }
}

class Point <: Equatable<Point> {
    var x: Float64 = 0.0
    var y: Float64 = 0.0

    public operator func ==(that: Point): Bool {
        return this.x == that.x && this.y == that.y
    }

    public operator func !=(that: Point): Bool {
        return !(this == that)
    }
}

class Transform {
    var x: Float64 = 0.0
    var y: Float64 = 0.0
    var scaleX: Float64 = 0.0
    var scaleY: Float64 = 0.0
    var rotation: Float64 = 0.0
}

class MatrixValue {
    var a: Float64 = 0.0
    var b: Float64 = 0.0
    var c: Float64 = 0.0
    var d: Float64 = 0.0
    var tx: Float64 = 0.0
    var ty: Float64 = 0.0

    func multiply(m1: MatrixValue, m2: MatrixValue): Unit {
        a = m1.a * m2.a + m1.c * m2.b
        b = m1.b * m2.a + m1.d * m2.b
        c = m1.a * m2.c + m1.c * m2.d
        d = m1.b * m2.c + m1.d * m2.d
        tx = m1.a * m2.tx + m1.c * m2.ty + m1.tx
        ty = m1.b * m2.tx + m1.d * m2.ty + m1.ty
    }
}

public class Matrix2D2 {
    static let DEG_TO_RAD: Float64 = Float64.PI / 180.0
    static let ident: Matrix2D2 = Matrix2D2()
    var a: Float64 = 1.0
    var b: Float64 = 0.0
    var c: Float64 = 0.0
    var d: Float64 = 1.0
    var tx: Float64 = 0.0
    var ty: Float64 = 0.0

    init() {}

    static func toMatrix(matrix: Array<Float64>): Matrix2 {
        return Matrix2(matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5])
    }

    func getE(): Float64 {
        return this.tx
    }

    func getF(): Float64 {
        return this.ty
    }

    func setValues(a!: Float64 = 1.0, b!: Float64 = 0.0, c!: Float64 = 0.0, d!: Float64 = 1.0, tx!: Float64 = 0.0, ty!: Float64 = 0.0): Matrix2D2 {
        this.a = a
        this.b = b
        this.c = c
        this.d = d
        this.tx = tx
        this.ty = ty
        return this
    }

    func append(a: Float64, b: Float64, c: Float64, d: Float64, tx: Float64, ty: Float64): Matrix2D2 {
        let a1 = this.a
        let b1 = this.b
        let c1 = this.c
        let d1 = this.d
        if (a != 1.0 || b != 0.0 || c != 0.0 || d != 1.0) {
            this.a = a1 * a + c1 * b
            this.b = b1 * a + d1 * b
            this.c = a1 * c + c1 * d
            this.d = b1 * c + d1 * d
        }
        this.tx = a1 * tx + c1 * ty + this.tx
        this.ty = b1 * tx + d1 * ty + this.ty
        return this
    }

    func prepend(a: Float64, b: Float64, c: Float64, d: Float64, tx: Float64, ty: Float64): Matrix2D2 {
        let a1 = this.a
        let c1 = this.c
        let tx1 = this.tx
        this.a = a * a1 + c * this.b
        this.b = b * a1 + d * this.b
        this.c = a * c1 + c * this.d
        this.d = b * c1 + d * this.d
        this.tx = a * tx1 + c * this.ty + tx
        this.ty = b * tx1 + d * this.ty + ty
        return this
    }

    func appendMatrix(matrix: Matrix2D2): Matrix2D2 {
        return append(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty)
    }

    func prependMatrix(matrix: Matrix2D2): Matrix2D2 {
        return prepend(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty)
    }

    func appendTransform(
        x: Float64,
        y: Float64,
        scaleX: Float64,
        scaleY: Float64,
        ro: Int64,
        sX: Float64,
        sY: Float64,
        regX!: Float64 = 0.0,
        regY!: Float64 = 0.0
    ): Matrix2D2 {
        var skewX: Float64 = sX
        var skewY: Float64 = sY
        var rotation: Float64 = Float64(ro)
        var c: Float64 = 1.0
        var s: Float64 = 0.0
        if ((ro % 360) != 0) {
            let r = rotation * Matrix2D2.DEG_TO_RAD
            c = cos(r)
            s = sin(r)
        }
        if (sX != 0.0 || sY != 0.0) {
            skewX *= Matrix2D2.DEG_TO_RAD
            skewY *= Matrix2D2.DEG_TO_RAD
            append(cos(skewY), sin(skewY), -sin(skewX), cos(skewX), x, y)
            append(c * scaleX, s * scaleX, -s * scaleY, c * scaleY, 0.0, 0.0)
        } else {
            append(c * scaleX, s * scaleX, -s * scaleY, c * scaleY, x, y)
        }
        if (regX != 0.0 || regY != 0.0) {
            this.tx -= regX * this.a + regY * this.c
            this.ty -= regX * this.b + regY * this.d
        }
        return this
    }

    func prependTransform(
        x: Float64,
        y: Float64,
        scaleX: Float64,
        scaleY: Float64,
        ro: Int64,
        sX: Float64,
        sY: Float64,
        regX!: Float64 = 0.0,
        regY!: Float64 = 0.0
    ): Matrix2D2 {
        var skewX: Float64 = sX
        var skewY: Float64 = sY
        var rotation: Float64 = Float64(ro)
        var c: Float64 = 1.0
        var s: Float64 = 0.0
        if ((ro % 360) != 0) {
            let r = rotation * Matrix2D2.DEG_TO_RAD
            c = cos(r)
            s = sin(r)
        }

        if (regX != 0.0 || regY != 0.0) {
            this.tx -= regX
            this.ty -= regY
        }
        if (sX != 0.0 || sY != 0.0) {
            skewX *= Matrix2D2.DEG_TO_RAD
            skewY *= Matrix2D2.DEG_TO_RAD
            prepend(c * scaleX, s * scaleX, -s * scaleY, c * scaleY, 0.0, 0.0)
            prepend(cos(skewY), sin(skewY), -sin(skewX), cos(skewX), x, y)
        } else {
            prepend(c * scaleX, s * scaleX, -s * scaleY, c * scaleY, x, y)
        }
        return this
    }

    func rotate(a: Float64, cx!: Float64 = Float64.NaN, cy!: Float64 = Float64.NaN): Matrix2D2 {
        let hasOriginPoint = !cx.isNaN() && !cy.isNaN()
        let angle: Float64 = a * Matrix2D2.DEG_TO_RAD
        let c: Float64 = cos(angle)
        let s: Float64 = sin(angle)
        if (hasOriginPoint) {
        	translate(cx, y: cy)
        }
        let a1 = this.a
        let b1 = this.b
        this.a = a1 * c + this.c * s
        this.b = b1 * c + this.d * s
        this.c = -a1 * s + this.c * c
        this.d = -b1 * s + this.d * c
        if (hasOriginPoint) {
        	translate(-cx, y: -cy)
        }
        return this
    }

    func skew(sX: Float64, sY: Float64): Matrix2D2 {
        var skewX = sX
        var skewY = sY
        skewX = skewX * Matrix2D2.DEG_TO_RAD
        skewY = skewY * Matrix2D2.DEG_TO_RAD
        append(1.0, tan(skewY), tan(skewX), 1.0, 0.0, 0.0)
        return this
    }

    func skewX(skewX: Float64): Matrix2D2 {
        return skew(skewX, 0.0)
    }

    func skewY(skewY: Float64): Matrix2D2 {
        return skew(0.0, skewY)
    }

    func scale(x: Float64, y!: Float64 = Float64.NaN, cx!: Float64 = Float64.NaN, cy!: Float64 = Float64.NaN): Matrix2D2 {
        var scaleY = y
        let hasOriginPoint: Bool = !cx.isNaN() && !cy.isNaN()
        if (scaleY.isNaN()) {
            scaleY = x
        }
        if (hasOriginPoint) {
            translate(cx, y: cy)
        }
        this.a *= x
        this.b *= x
        this.c *= scaleY
        this.d *= scaleY
        if (hasOriginPoint) {
            translate(-cx, y: -cy)
        }
        return this
    }

    func scaleX(x: Float64): Matrix2D2 {
        return scale(x, y: 1.0)
    }

    func scaleX(x: Float64, cx: Float64, cy: Float64): Matrix2D2 {
        return scale(x, y: 1.0, cx: cx, cy: cy)
    }

    func scaleY(y: Float64): Matrix2D2 {
        return scale(1.0, y: y)
    }

    func scaleY(y: Float64, cx: Float64, cy: Float64): Matrix2D2 {
        return scale(1.0, y: y, cx: cx, cy: cy)
    }

    func translate(x: Float64, y!: Float64 = 0.0): Matrix2D2 {
        this.tx += this.a * x + this.c * y
        this.ty += this.b * x + this.d * y
        return this
    }

    func translateX(x: Float64): Matrix2D2 {
        return translate(x)
    }

    func translateY(y: Float64): Matrix2D2 {
        return translate(0.0, y: y)
    }

    func flipX(): Matrix2D2 {
        return append(1.0, 0.0, 0.0, -1.0, 0.0, 0.0)
    }

    func flipY(): Matrix2D2 {
        return append(-1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
    }

    func flipOrigin(): Matrix2D2 {
        return append(-1.0, 0.0, 0.0, -1.0, 0.0, 0.0)
    }

    func identity(): Matrix2D2 {
        this.a = 1.0
        this.d = 1.0
        this.b = 0.0
        this.c = 0.0
        this.tx = 0.0
        this.ty = 0.0
        return this
    }

    func invert(): Matrix2D2 {
        let a1 = this.a
        let b1 = this.b
        let c1 = this.c
        let d1 = this.d
        let tx1 = this.tx
        let n = a1 * d1 - b1 * c1
        this.a = d1 / n
        this.b = -b1 / n
        this.c = -c1 / n
        this.d = a1 / n
        this.tx = (c1 * this.ty - d1 * tx1) / n
        this.ty = -(a1 * this.ty - b1 * tx1) / n
        return this
    }

    func isIdentity(): Bool {
        return (this.tx == 0.0 && this.ty == 0.0 && this.a == 1.0 && this.b == 0.0 && this.c == 0.0 && this.d == 1.0)
    }

    func equals(matrix: Matrix2D2): Bool {
        return (this.tx == matrix.tx && this.ty == matrix.ty && this.a == matrix.a && this.b == matrix.b && this.c ==
            matrix.c && this.d == matrix.d)
    }

    func transformPoint(x1: Float64, y1: Float64, origin!: Point = Point()): Point {
        var x: Float64 = x1
        var y: Float64 = y1
        let hasOriginPoint: Bool = origin != Point()
        if (hasOriginPoint) {
            x = x - origin.x
            y = y - origin.y
        }
        let pt = Point()
        pt.x = x * this.a + y * this.c + this.tx
        pt.y = x * this.b + y * this.d + this.ty
        if (hasOriginPoint) {
            pt.x += origin.x
            pt.y += origin.y
        }
        return pt
    }

    func transformPoints(points: Array<Point>, origin: Point): Array<Point> {
        let transformedPoints: ArrayList<Point> = ArrayList<Point>()
        for (point in points) {
            transformedPoints.append(transformPoint(point.x, point.y, origin: origin))
        }
        return transformedPoints.toArray()
    }

    func transformPointWithOrigin(x: Float64, y: Float64, origin: Point): Point {
        return transformPoint(x, y, origin: origin)
    }

    func copy(matrix: Matrix2D2): Matrix2D2 {
        return setValues(a: matrix.a, b: matrix.b, c: matrix.c, d: matrix.d, tx: matrix.tx, ty: matrix.ty)
    }

    func toString(): String {
        return ("[Matrix2D2 (a=" + "${this.a}" + " b=" + "${this.b}" + " c=" + "${this.c}" + " d=" + "${this.d}" + " tx=" +
            "${this.tx}" + " ty=" + "${this.ty}" + ")]")
    }
}
