/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

public class MyRect {
    var left: Float64 = 0.0
    var top: Float64 = 0.0
    var right: Float64 = 0.0
    var bottom: Float64 = 0.0

    init(left!: Float64 = 0.0, top!: Float64 = 0.0, right!: Float64 = 0.0, bottom!: Float64 = 0.0, r!: ?MyRect = None) {
        this.left = left
        this.top = top
        this.right = right
        this.bottom = bottom
        if (let Some(v) <- r) {
            this.left = v.left
            this.top = v.top
            this.right = v.right
            this.bottom = v.bottom
        }
    }

    public static func copyOrNull(r: ?MyRect): MyRect {
        if (let Some(v) <- r) {
            return MyRect(left: v.left, top: v.top, right: v.right, bottom: v.bottom, r: v)
        }
        return MyRect()
    }

    public func isEmpty(): Bool {
        return this.left >= this.right || this.top >= this.bottom
    }

    public func width(): Float64 {
        return this.right - this.left
    }

    public func height(): Float64 {
        return this.bottom - this.top
    }

    public func centerX(): Float64 {
        return (this.left + this.right) / 2.0
    }

    public func centerY(): Float64 {
        return (this.top + this.bottom) / 2.0
    }

    public func exactCenterX(): Float64 {
        return (this.left + this.right) * 0.5
    }

    public func exactCenterY(): Float64 {
        return (this.top + this.bottom) * 0.5
    }

    public func setEmpty(): Unit {
        this.left = 0.0
        this.right = 0.0
        this.top = 0.0
        this.bottom = 0.0
    }

    public func set(left: Float64, top: Float64, right: Float64, bottom: Float64): Unit {
        this.left = left
        this.top = top
        this.right = right
        this.bottom = bottom
    }

    public func offset(dx: Float64, dy: Float64): Unit {
        this.left += dx
        this.top += dy
        this.right += dx
        this.bottom += dy
    }

    public func offsetTo(newLeft: Float64, newTop: Float64): Unit {
        this.right += newLeft - this.left
        this.bottom += newTop - this.top
        this.left = newLeft
        this.top = newTop
    }

    public func inset(left: Float64, top: Float64, right: Float64, bottom: Float64): Unit {
        this.left += left
        this.top += top
        this.right -= right
        this.bottom -= bottom
    }

    public func contains(x: Float64, y: Float64): Bool {
        return this.left < this.right && this.top < this.bottom && x >= this.left && x < this.right && y >= this.top &&
            y < this.bottom
    }
}
