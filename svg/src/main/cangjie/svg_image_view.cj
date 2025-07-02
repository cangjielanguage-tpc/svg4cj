/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

import ohos.state_macro_manage.*
import ohos.concurrency.*

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
                this.model.canvasReadyflag = true
                this.model.setContext2D(this.context2D)
                this.model.viewWidth = this.context2D.width()
                this.model.viewHeight = this.context2D.height()
                this.model.doRender(this.model.context, areaChanged: true)
            }
        )
    }
}

@Observed
public class SVGImageViewModel {
    @Publish
    var svg: ?SVG = Option<SVG>.None
    var renderOptions: RenderOptionsBase = RenderOptionsBase()
    var settings: RenderingContextSettings = RenderingContextSettings(antialias: true)
    var context2D: CanvasRenderingContext2D = CanvasRenderingContext2D(settings)
    var canvas: CanvasImpl = CanvasImpl(this.context2D)
    var render: ?SVGRenderer = Option<SVGRenderer>.None
    var viewWidth: Float64 = Float64(getDefaultDisplaySync().width)
    var viewHeight: Float64 = Float64(getDefaultDisplaySync().height)
    var context: ?AbilityContext = Option<AbilityContext>.None
    var scaleX: Float64 = 0.0
    var scaleY: Float64 = 0.0
    var needScale: Bool = true
    var canvasReadyflag: Bool = false
    private var renderGeneration: Int64 = 0
    private var rendering: Bool = false
    private var renderPending: Bool = false

    public func setContext2D(context2D: CanvasRenderingContext2D): Unit {
        this.context2D = context2D
        this.canvas = CanvasImpl(this.context2D)
    }

    private func resetCanvas(): Unit {
        this.canvas.resetTransform()
        this.canvas.clear()
        this.needScale = true
        this.scaleX = 0.0
        this.scaleY = 0.0
    }

    private static func isValidPixelMapDimension(value: Float64): Bool {
        return !value.isNaN() && value > 0.0 && value < Float64.Max
    }

    private func restore(): Unit {
        this.renderOptions.css = ""
        this.needScale = true
        this.scaleX = 0.0
        this.scaleY = 0.0
    }

    public func setSVG(svg: SVG, context: ?AbilityContext, css!: String = this.renderOptions.css): Unit {
        let cssValue = css
        restore()
        if (context.isSome()) {
            this.context = context
        }
        this.svg = svg
        if (cssValue != "") {
            this.renderOptions.css = cssValue
        }
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
        restore()
        if (context.isSome()) {
            this.context = context
        }
        SVG.getFromResource(
            resource,
            {
                v: SVG => launch {
                    this.svg = v
                    doRender(context)
                }
            },
            context()
        )
    }

    public func setImageRawfile(filename: String, context: ?AbilityContext): Unit {
        restore()
        if (context.isSome()) {
            this.context = context
        }
        SVG.getFromRawfile(
            filename,
            {
                v: SVG => launch {
                    this.svg = v
                    doRender(context)
                }
            },
            context()
        )
    }

    public func setFromString(data: String, context: ?AbilityContext): Unit {
        restore()
        if (context.isSome()) {
            this.context = context
        }
        SVG.getFromString(
            data,
            {
                v: SVG => launch {
                    this.svg = v
                    doRender(context)
                }
            }
        )
    }

    public func doRender(context: ?AbilityContext, areaChanged!: Bool = false): Unit {
        if (context.isSome()) {
            this.context = context
        }
        if (!this.canvasReadyflag) {
            return
        }
        if (this.svg.isNone()) {
            return
        }
        this.renderGeneration++
        this.renderPending = true
        if (this.rendering) {
            return
        }
        this.rendering = true
        launch {
            try {
                while (this.renderPending) {
                    this.renderPending = false
                    let generation = this.renderGeneration
                    if (let Some(v) <- this.svg) {
                        resetCanvas()
                        if (this.needScale || areaChanged) {
                            let viewBoxWidth = px2vpValue(v.getRootElement().viewBox.width)
                            let viewBoxHeight = px2vpValue(v.getRootElement().viewBox.height)
                            let xScale = this.viewWidth / viewBoxWidth
                            let yScale = this.viewHeight / viewBoxHeight
                            this.scaleX = min(xScale, yScale)
                            this.scaleY = min(xScale, yScale)
                            this.context2D.scale(this.scaleX, this.scaleY)
                            this.needScale = false
                        }
                        let renderer = SVGRenderer(this.canvas, v.base.renderDPI, v.base.externalFileResolver)
                        this.render = renderer
                        renderer.renderDocument(v.base, this.renderOptions, context).get()
                        if (generation != this.renderGeneration) {
                            this.renderPending = true
                        }
                    }
                }
            } finally {
                this.rendering = false
            }
            if (this.renderPending) {
                this.doRender(context)
            }
        }
    }

    public func getSVGPixelMap(data: Array<UInt8>, context: ?AbilityContext): PixelMap {
        if (context.isSome()) {
            this.context = context
        }
        let value: String = String.fromUtf8(data)
        let svgBase = SVGParserImpl().setConvertTransformsToVp(false).parseString(value)
        let svgInstance = SVG(svgBase)
        let setTings: RenderingContextSettings = RenderingContextSettings(antialias: true)
        let svgRootElement = svgInstance.getRootElement()
        let unitScale: Float64 = px2vpValue(1.0)
        let targetCompWidth: Float64 = this.viewWidth * unitScale
        let targetCompHeight: Float64 = this.viewHeight * unitScale
        let viewBoxWidth: Float64 = svgRootElement.viewBox.width
        let viewBoxHeight: Float64 = svgRootElement.viewBox.height
        if (!isValidPixelMapDimension(targetCompWidth) ||
            !isValidPixelMapDimension(targetCompHeight) ||
            !isValidPixelMapDimension(viewBoxWidth) ||
            !isValidPixelMapDimension(viewBoxHeight)) {
            throw SVGParseException("Invalid SVG dimensions for pixel map")
        }
        let offContext: OffscreenCanvasRenderingContext2D = OffscreenCanvasRenderingContext2D(targetCompWidth, targetCompHeight, setTings)
        var minScale: Float64 = 1.0
        let scaleW: Float64 = targetCompWidth / px2vpValue(viewBoxWidth)
        let scaleH: Float64 = targetCompHeight / px2vpValue(viewBoxHeight)
        minScale = min(scaleW, scaleH)
        offContext.setTransform(minScale, 0.0, 0.0, minScale, 0.0, 0.0)
        canvas.setOffScreenCanvas(offContext, targetCompWidth, targetCompHeight)
        try {
            render = SVGRenderer(canvas, svgInstance.base.renderDPI, svgInstance.base.externalFileResolver)
            render().renderDocument(svgInstance.base, renderOptions, context).get()
            let minShowWidth: Float64 = px2vpValue(viewBoxWidth) * minScale
            let minShowHeight: Float64 = px2vpValue(viewBoxHeight) * minScale
            return offContext.getPixelMap(0.0, 0.0, minShowWidth, minShowHeight)
        } finally {
            canvas.clearOffScreenCanvas()
        }
    }
}
