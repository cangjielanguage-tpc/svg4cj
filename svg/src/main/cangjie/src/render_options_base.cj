/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public open class RenderOptionsBase {
    var css: String = ""
    var cssRuleset: ?RuleSet = None
    var preserveAspectRatio: ?PreserveAspectRatio = None
    var targetId: String = ""
    var viewBox: Box = Box(0.0, 0.0, 0.0, 0.0)
    var viewId: String = ""
    var viewPort: Box = Box(0.0, 0.0, 0.0, 0.0)

    init() {}

    public static func create(): RenderOptionsBase {
        return RenderOptionsBase()
    }

    init(other: RenderOptionsBase) {
        this.css = other.css
        this.cssRuleset = other.cssRuleset
        this.preserveAspectRatio = other.preserveAspectRatio
        this.viewBox = other.viewBox
        this.viewId = other.viewId
        this.viewPort = other.viewPort
        this.targetId = other.targetId
    }

    public open func setCss(css: String): RenderOptionsBase {
        this.css = css
        return this
    }

    public open func setCss(css: CSS): RenderOptionsBase {
        this.cssRuleset = css.cssRuleset
        this.css = ""
        return this
    }

    public open func hasCss(): Bool {
        return !this.css.isEmpty() && this.css.trimAscii().size > 0 || this.cssRuleset.isSome()
    }

    public open func setPreserveAspectRatio(preserveAspectRatio: PreserveAspectRatio): RenderOptionsBase {
        this.preserveAspectRatio = preserveAspectRatio
        return this
    }

    public open func hasPreserveAspectRatio(): Bool {
        return this.preserveAspectRatio.isSome()
    }

    public open func setView(viewId: String): RenderOptionsBase {
        this.viewId = viewId
        return this
    }

    public open func hasView(): Bool {
        return !this.viewId.isEmpty()
    }

    public open func setViewBox(minX: Float64, minY: Float64, width: Float64, height: Float64): RenderOptionsBase {
        this.viewBox = Box(minX, minY, width, height)
        return this
    }

    public open func hasViewBox(): Bool {
        return this.viewBox != Box(0.0, 0.0, 0.0, 0.0)
    }

    public open func setViewPort(minX: Float64, minY: Float64, width: Float64, height: Float64): RenderOptionsBase {
        this.viewPort = Box(minX, minY, width, height)
        return this
    }

    public open func hasViewPort(): Bool {
        return this.viewPort != Box(0.0, 0.0, 0.0, 0.0)
    }

    public open func setTarget(targetId: String): RenderOptionsBase {
        this.targetId = targetId
        return this
    }

    public open func hasTarget(): Bool {
        return !this.targetId.isEmpty()
    }
}
