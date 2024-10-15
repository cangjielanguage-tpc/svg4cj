/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

import ohos.state_macro_manage.*

@Component
public class SVGImageView {
    @State
    var model: SVGImageViewModel = SVGImageViewModel()
    private var settings: RenderingContextSettings = RenderingContextSettings(antialias: true)
    private let context2D: CanvasRenderingContext2D = CanvasRenderingContext2D(this.settings)

    func build() {
        Canvas(this.context2D).width(100.percent).height(100.percent).onReady(
            {
                =>
                this.model.setContext2D(this.context2D)
                //                this.model.viewWidth = this.context2D.width TODO..
                this.model.viewWidth = 153
                //                this.model.viewHeight = this.context2D.height TODO..
                this.model.viewHeight = 360
                this.model.doRender(this.model.context, areaChanged: true)
            }
        )
    }
}

public class SVGImageViewModel {
    private var svg: ?SVG = None
    private var renderOptions: RenderOptionsBase = RenderOptionsBase()
    private var context2D: CanvasRenderingContext2D
    var canvas: CanvasImpl
    var render: ?SVGRenderer = None
    var viewWidth: Int32 = getDefaultDisplaySync().width
    var viewHeight: Int32 = getDefaultDisplaySync().height
    var context: ?AbilityContext = None
    var scaleX: Float64 = 0.0
    var scaleY: Float64 = 0.0
    var needScale: Bool = true

    public init() {
        var settings: RenderingContextSettings = RenderingContextSettings(antialias: true)
        this.context2D = CanvasRenderingContext2D(settings)
        this.canvas = CanvasImpl(this.context2D)
    }

    public func setContext2D(context2D: CanvasRenderingContext2D): Unit {
        this.context2D = context2D
        this.canvas = CanvasImpl(this.context2D)
    }

    public func setSVG(svg: SVG, context: ?AbilityContext, css!: String = this.renderOptions.css): Unit {
        if (context.isSome()) {
            this.context = context
        }
        this.svg = svg
        doRender(context)
    }

    public func setCSS(css: String, context: ?AbilityContext): Unit {
        this.renderOptions.css = css
        if (context.isSome()) {
            this.context = context
        }
        doRender(context)
    }

    public func setImageResource(resource: OhosResource, context: ?AbilityContext): Unit {
        if (context.isSome()) {
            this.context = context
        }
        SVG.getFromResource(
            resource,
            {
                v: SVG =>
                this.svg = v
                doRender(context)
            },
            context()
        )
    }

    public func setImageRawfile(filename: String, context: ?AbilityContext): Unit {
        if (context.isSome()) {
            this.context = context
        }
        SVG.getFromRawfile(
            filename,
            {
                v: SVG =>
                this.svg = v
                doRender(context)
            },
            context()
        )
    }

    public func setFromString(url: String, context: ?AbilityContext): Unit {
        if (context.isSome()) {
            this.context = context
        }
        this.svg = SVG.getFromString(url)
        doRender(context)
    }

    public func doRender(context: ?AbilityContext, areaChanged!: Bool = false): Unit {
        if (context.isSome()) {
            this.context = context
        }
        if (this.svg.isNone()) {
            return
        }
        if (let Some(v) <- this.svg) {
            if (this.needScale || areaChanged) {
                let viewBoxWidth = (px2vp(Length(v.getRootElement().viewBox.width, unitType: LengthType.px)) ?? Length(
                    0.0, unitType: LengthType.px)).value
                let viewBoxHeight = (px2vp(Length(v.getRootElement().viewBox.height, unitType: LengthType.px)) ??
                    Length(0.0, unitType: LengthType.px)).value
                let xScale = Float64(this.viewWidth) / viewBoxWidth
                let yScale = Float64(this.viewHeight) / viewBoxHeight
                this.scaleX = min(xScale, yScale)
                this.scaleY = min(xScale, yScale)
                this.context2D.scale(this.scaleX, this.scaleY)
                this.needScale = false
            }
            this.render = SVGRenderer(this.canvas, v.base.renderDPI, v.base.externalFileResolver)
            this.render().renderDocument(v.base, this.renderOptions, context)
        } else {
            return
        }
    }

    public func getSVGPixelMap(data: Array<UInt8>, context: ?AbilityContext): PixelMap {
        if (context.isSome()) {
            this.context = context
        }
        this.svg = SVG.getFromString(String.fromUtf8(data))
        let svgRootElement = this.svg().getRootElement()
        // 根据屏幕分辨率适配
        let targetCompWidth: Float64 = if (let Some(v) <- px2vp(Length(1.0, unitType: LengthType.px))) {
            Float64(this.viewWidth) * v.value
        } else {
            0.0
        }
        let targetCompHeight: Float64 = if (let Some(v) <- px2vp(Length(1.0, unitType: LengthType.px))) {
            Float64(this.viewHeight) * v.value
        } else {
            0.0
        }
        var minScale: Float64 = 1.0
        let scaleW: Float64 = targetCompWidth / svgRootElement.viewBox.width * 1.0
        let scaleH: Float64 = targetCompHeight / svgRootElement.viewBox.height * 1.0
        minScale = min(scaleW, scaleH) // 选择较小的缩放比例以确保完全适应目标尺寸
        this.context2D.setTransform(minScale, 0.0, 0.0, minScale, 0.0, 0.0)
        this.render = SVGRenderer(this.canvas, this.svg().base.renderDPI, this.svg().base.externalFileResolver)
        this.render().renderDocument(this.svg().base, this.renderOptions, this.context)
        let minShowWidth: Float64 = if (let Some(v) <- px2vp(Length(1.0, unitType: LengthType.px))) {
            svgRootElement.viewBox.width * v.value * minScale
        } else {
            0.0
        }
        let minShowHeight: Float64 = if (let Some(v) <- px2vp(Length(1.0, unitType: LengthType.px))) {
            svgRootElement.viewBox.height * v.value * minScale
        } else {
            0.0
        }
        let pix = this.context2D.getPixelMap(0.0, 0.0, minShowWidth, minShowHeight)
        this.context2D.clearRect(0.0, 0.0, minShowWidth, minShowHeight)
        return pix
    }
}
