/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

public class SVGRenderer {
    private static let BEZIER_ARC_FACTOR: Float64 = 0.5522847498
    public static let LUMINANCE_TO_ALPHA_RED: Float64 = 0.2127
    public static let LUMINANCE_TO_ALPHA_GREEN: Float64 = 0.7151
    public static let LUMINANCE_TO_ALPHA_BLUE: Float64 = 0.0722
    private var state: RendererState = RendererState(Option<RendererState>.None)
    private var canvas: CanvasImpl
    private var dpi: Float64
    private var document: ?SVGBase = None
    private var externalFileResolver: SVGExternalFileResolver
    private var combinedPath: ?Path2D = None
    private var ruleMatchContext: RuleMatchContext = RuleMatchContext()
    private var stateStack: LinkedList<RendererState> = LinkedList<RendererState>()
    private var parentStack: LinkedList<SvgContainer> = LinkedList<SvgContainer>()
    private var matrixStack: LinkedList<Matrix2D2> = LinkedList<Matrix2D2>()

    init(canvas: CanvasImpl, defaultDPI: Float64, externalFileResolver: SVGExternalFileResolver) {
        this.canvas = canvas
        this.dpi = defaultDPI
        this.externalFileResolver = externalFileResolver
    }

    private func resetState(): Unit {
        this.state = RendererState(Option<RendererState>.None)
        this.stateStack = LinkedList<RendererState>()
        updateStyle(this.state, Style.getDefaultStyle())
        this.state.spacePreserve = false
        this.stateStack.addLast(RendererState(this.state))
        this.matrixStack = LinkedList<Matrix2D2>()
        this.parentStack = LinkedList<SvgContainer>()
    }

    private func updateStyle(state: RendererState, style: Style): Unit {
        if (isSpecified(style, Style.SPECIFIED_COLOR)) {
            state.style.color = style.color
        }

        if (isSpecified(style, Style.SPECIFIED_OPACITY)) {
            state.style.opacity = style.opacity
        }

        if (isSpecified(style, Style.SPECIFIED_FILL)) {
            state.style.fill = style.fill
            if (style.fill.isSome() && style.fill() != Colour.TRANSPARENT) {
                state.hasFill = true
            } else {
                state.hasFill = false
            }
        }

        if (isSpecified(style, Style.SPECIFIED_FILL_OPACITY)) {
            state.style.fillOpacity = style.fillOpacity
        } else {
            state.style.fillOpacity = 1.0
        }

        if (isSpecified(style,
            Style.SPECIFIED_FILL | Style.SPECIFIED_FILL_OPACITY | Style.SPECIFIED_COLOR | Style.SPECIFIED_OPACITY)) {
            if (let Some(v) <- state.style.fill) {
                setPaintColour(state, true, v)
            }
        }

        if (isSpecified(style, Style.SPECIFIED_FILL_RULE)) {
            state.style.fillRule = style.fillRule
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE)) {
            state.style.stroke = style.stroke
            if (style.stroke.isSome() && style.stroke() != Colour.TRANSPARENT) {
                state.hasStroke = true
            } else {
                state.hasStroke = false
            }
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_OPACITY)) {
            state.style.strokeOpacity = style.strokeOpacity
        }

        if (isSpecified(style,
            Style.SPECIFIED_STROKE | Style.SPECIFIED_STROKE_OPACITY | Style.SPECIFIED_COLOR | Style.SPECIFIED_OPACITY)) {
            if (let Some(v) <- state.style.stroke) {
                setPaintColour(state, false, v)
            }
        }

        if (isSpecified(style, Style.SPECIFIED_VECTOR_EFFECT)) {
            state.style.vectorEffect = style.vectorEffect
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_WIDTH)) {
            state.style.strokeWidth = style.strokeWidth
            state.strokePaint.setStrokeWidth(state.style.strokeWidth.floatValue(this))
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_LINECAP)) {
            state.style.strokeLineCap = style.strokeLineCap
            if (let Some(v) <- style.strokeLineCap) {
                match (v) {
                    case LineCap.Butt => state.strokePaint.setLineCap(LineCapStyle.Butt)
                    case LineCap.Round => state.strokePaint.setLineCap(LineCapStyle.Round)
                    case LineCap.Square => state.strokePaint.setLineCap(LineCapStyle.Square)
                    case _ => ()
                }
            }
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_LINEJOIN)) {
            state.style.strokeLineJoin = style.strokeLineJoin
            if (let Some(v) <- style.strokeLineJoin) {
                match (v) {
                    case LineJoin.Miter => state.strokePaint.setLineJoin(LineJoinStyle.Miter)
                    case LineJoin.Round => state.strokePaint.setLineJoin(LineJoinStyle.Round)
                    case LineJoin.Bevel => state.strokePaint.setLineJoin(LineJoinStyle.Bevel)
                    case _ => ()
                }
            }
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_MITERLIMIT)) {
            state.style.strokeMiterLimit = style.strokeMiterLimit
            state.strokePaint.setStrokeMiterLimit(style.strokeMiterLimit)
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_DASHARRAY)) {
            state.style.strokeDashArray = style.strokeDashArray
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_DASHOFFSET)) {
            state.style.strokeDashOffset = style.strokeDashOffset
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_DASHARRAY | Style.SPECIFIED_STROKE_DASHOFFSET)) {
            if (state.style.strokeDashArray.isEmpty()) {
                state.strokePaint.setStrokeDashArray(ArrayList<Float64>())
            } else {
                var intervalSum: Float64 = 0.0
                let n: Int64 = state.style.strokeDashArray.size
                let arrayLen: Int64 = if (n % 2 == 0) {
                    n
                } else {
                    n * 2
                }
                var intervals: ArrayList<Float64> = ArrayList<Float64>(arrayLen)
                for (i in 0..arrayLen) {
                    intervals.add(state.style.strokeDashArray[i % n].floatValue(this), at: i)
                    intervalSum += intervals[i]
                }
                if (intervalSum == 0.0) {
                } else {
                    var offset = this.state.style.strokeDashOffset.floatValue(this)
                    if (offset < 0.0) {
                        offset = intervalSum + Float64((Int64(offset) % Int64(intervalSum)))
                    }
                    state.strokePaint.setStrokeDashArray(intervals)
                    state.strokePaint.setStrokeDashOffset(Int64(offset))
                }
            }
        }

        if (isSpecified(style, Style.SPECIFIED_FONT_SIZE)) {
            let currentFontSize: Float64 = getCurrentFontSize()
            state.style.fontSize = style.fontSize
            state.fillPaint.setFontSize(style.fontSize.floatValue(this, max: currentFontSize))
            state.strokePaint.setFontSize(style.fontSize.floatValue(this, max: currentFontSize))
        }

        if (isSpecified(style, Style.SPECIFIED_FONT_FAMILY)) {
            state.style.fontFamily = style.fontFamily
        }

        if (isSpecified(style, Style.SPECIFIED_FONT_WEIGHT)) {
            if (style.fontWeight == Style.FONT_WEIGHT_LIGHTER) {
                let fw = this.state.style.fontWeight
                if (fw >= 100.0 && fw < 550.0) {
                    state.style.fontWeight = 100.0
                } else if (fw >= 550.0 && fw < 750.0) {
                    state.style.fontWeight = 400.0
                } else if (fw >= 750.0) {
                    state.style.fontWeight = 700.0
                }
            } else if (style.fontWeight == Style.FONT_WEIGHT_BOLDER) {
                let fw = this.state.style.fontWeight
                if (fw < 350.0) {
                    state.style.fontWeight = 400.0
                } else if (fw >= 350.0 && fw < 550.0) {
                    state.style.fontWeight = 700.0
                } else if (fw >= 550.0 && fw < 900.0) {
                    state.style.fontWeight = 900.0
                }
            } else {
                state.style.fontWeight = style.fontWeight
            }
        }

        if (isSpecified(style, Style.SPECIFIED_FONT_STYLE)) {
            state.style.fontStyle = style.fontStyle
        }

        if (isSpecified(style, Style.SPECIFIED_FONT_STRETCH)) {
            state.style.fontStretch = style.fontStretch
        }

        if (isSpecified(style, Style.SPECIFIED_DIRECTION)) {
            state.style.direction = style.direction
        }

        if (isSpecified(style, Style.SPECIFIED_TEXT_ANCHOR)) {
            state.style.textAnchor = style.textAnchor
        }

        if (isSpecified(style, Style.SPECIFIED_OVERFLOW)) {
            state.style.overflow = style.overflow
        }

        if (isSpecified(style, Style.SPECIFIED_MARKER_START)) {
            state.style.markerStart = style.markerStart
        }

        if (isSpecified(style, Style.SPECIFIED_MARKER_MID)) {
            state.style.markerMid = style.markerMid
        }

        if (isSpecified(style, Style.SPECIFIED_MARKER_END)) {
            state.style.markerEnd = style.markerEnd
        }

        if (isSpecified(style, Style.SPECIFIED_DISPLAY)) {
            state.style.display = style.display
        }

        if (isSpecified(style, Style.SPECIFIED_VISIBILITY)) {
            state.style.visibility = style.visibility
        }

        if (isSpecified(style, Style.SPECIFIED_CLIP)) {
            state.style.clip = style.clip
        }

        if (isSpecified(style, Style.SPECIFIED_CLIP_PATH)) {
            state.style.clipPath = style.clipPath
        }

        if (isSpecified(style, Style.SPECIFIED_CLIP_RULE)) {
            state.style.clipRule = style.clipRule
        }

        if (isSpecified(style, Style.SPECIFIED_MASK)) {
            state.style.mask = style.mask
        }

        if (isSpecified(style, Style.SPECIFIED_STOP_COLOR)) {
            state.style.stopColor = style.stopColor
        }

        if (isSpecified(style, Style.SPECIFIED_STOP_OPACITY)) {
            state.style.stopOpacity = style.stopOpacity
        }

        if (isSpecified(style, Style.SPECIFIED_VIEWPORT_FILL)) {
            state.style.viewportFill = style.viewportFill
        }

        if (isSpecified(style, Style.SPECIFIED_VIEWPORT_FILL_OPACITY)) {
            state.style.viewportFillOpacity = style.viewportFillOpacity
        }

        if (isSpecified(style, Style.SPECIFIED_IMAGE_RENDERING)) {
            state.style.imageRendering = style.imageRendering
        }

        if (isSpecified(style, Style.SPECIFIED_ISOLATION)) {
            state.style.isolation = style.isolation
        }

        if (isSpecified(style, Style.SPECIFIED_MIX_BLEND_MODE)) {
            state.style.mixBlendMode = style.mixBlendMode
        }

        if (isSpecified(style, Style.SPECIFIED_WRITING_MODE)) {
            state.style.writingMode = style.writingMode
        }

        if (isSpecified(style, Style.SPECIFIED_GLYPH_ORIENTATION_VERTICAL)) {
            state.style.glyphOrientationVertical = style.glyphOrientationVertical
        }

        if (isSpecified(style, Style.SPECIFIED_TEXT_ORIENTATION)) {
            state.style.textOrientation = style.textOrientation
        }
    }

    private func isSpecified(style: Style, flag: Int64): Bool {
        return (style.specifiedFlags & flag) != 0
    }

    private func setPaintColour(state: RendererState, isFill: Bool, paint: SvgPaint): Unit {
        var col: Color
        if (let Some(paint) <- (paint as Colour)) {
            col = paint.colour
        } else if (let Some(v) <- (paint as CurrentColor)) {
            col = state.style.color.colour
        } else {
            return
        }
        if (isFill) {
            state.fillPaint.setColor(col)
        } else {
            state.strokePaint.setColor(col)
        }
    }

    func getCurrentFontSize(): Float64 {
        return this.state.fillPaint.getFontSize()
    }

    func getCurrentFontXHeight(): Float64 {
        return this.state.fillPaint.getFontSize() / 2.0
    }

    func getDPI(): Float64 {
        return this.dpi
    }

    func getCurrentViewPortInUserUnits(): Box {
        if (this.state.viewBox != Box(0.0, 0.0, 0.0, 0.0)) {
            return this.state.viewBox
        } else {
            return this.state.viewPort
        }
    }

    func renderDocument(document: SVGBase, renderOptions: RenderOptionsBase, context: ?AbilityContext): Future<Unit> {
        spawn {
            this.document = document
            let rootObj: Svg = document.getRootElement()
            var viewBox: Box = Box(0.0, 0.0, 0.0, 0.0)
            var preserveAspectRatio: ?PreserveAspectRatio = None
            if (renderOptions.hasView()) {
                let obj: ?SvgElementBase = this.document().getElementById(renderOptions.viewId)
                if (let Some(v) <- obj) {
                    if (!(v is View)) {
                        return
                    }
                    if (let Some(view) <- (v as View)) {
                        viewBox = view.viewBox
                        preserveAspectRatio = view.preserveAspectRatio
                    } else {
                        return
                    }
                }
            } else {
                viewBox = if (renderOptions.hasViewBox()) {
                    renderOptions.viewBox
                } else {
                    rootObj.viewBox
                }
                preserveAspectRatio = if (renderOptions.hasPreserveAspectRatio()) {
                    renderOptions.preserveAspectRatio
                } else {
                    rootObj.preserveAspectRatio
                }
            }

            if (renderOptions.hasCss()) {
                if (renderOptions.css != "") {
                    let parser: CSSParser = CSSParser(source: Source.RenderOptions,
                        externalFileResolver: this.externalFileResolver)
                    document.addCSSRules(parser.parse(renderOptions.css))
                } else if (let Some(v) <- renderOptions.cssRuleset) {
                    document.addCSSRules(v)
                }
            }
            if (renderOptions.hasTarget()) {
                this.ruleMatchContext = RuleMatchContext()
                this.ruleMatchContext.targetElement = document.getElementById(renderOptions.targetId)
            }
            resetState()
            checkXMLSpaceAttribute(rootObj)
            statePush(isRootContext: true)
            var viewPort: Box
            if (renderOptions.hasViewPort()) {
                let optValue = renderOptions.viewPort
                viewPort = Box(optValue.minX, optValue.minY, optValue.width, optValue.height)
            } else {
                viewPort = Box(rootObj.viewBox.minX, rootObj.viewBox.minY, rootObj.viewBox.width, rootObj.viewBox.height
                )
            }
            if (!rootObj.width.isZero()) {
                viewPort.width = rootObj.width.floatValueBox(this)
            }

            if (!rootObj.height.isZero()) {
                viewPort.height = rootObj.height.floatValueBox(this)
            }
            renderSvg4(rootObj, viewPort, viewBox, preserveAspectRatio, context)
            statePop()
            if (renderOptions.hasCss()) {
                document.clearRenderCSSRules()
            }
        }
    }

    private func checkXMLSpaceAttribute(obj: SvgObject): Unit {
        if (let Some(v) <- (obj as SvgElementBase)) {
            let bobj: SvgElementBase = v
            if (bobj.spacePreserve != false) {
                this.state.spacePreserve = bobj.spacePreserve
            }
        } else {
            return
        }
    }

    private func statePush(isRootContext!: Bool = false) {
        if (isRootContext == true) {
        } else {
            this.canvas.save()
        }
        this.stateStack.addLast(this.state)
        this.state = RendererState(this.state)
    }

    private func statePop(): Unit {
        this.combinedPath = None
        this.canvas.restore()
        this.state = this.stateStack.removeLast() ?? RendererState(Option<RendererState>.None)
    }

    private func renderSvg4(obj: Svg, viewPort: Box, viewBox: Box, p: ?PreserveAspectRatio, context: ?AbilityContext): Unit {
        var positioning = p
        if (viewPort.width == 0.0 || viewPort.height == 0.0) {
            return
        }
        positioning = if (let Some(v) <- obj.preserveAspectRatio) {
            v
        } else {
            PreserveAspectRatio.LETTERBOX
        }
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        this.state.viewPort = viewPort
        if (!this.state.style.overflow) {
            setClipRect(this.state.viewPort.minX, this.state.viewPort.minY, this.state.viewPort.width,
                this.state.viewPort.height)
        }
        checkForClipPath(obj, boundingBox: this.state.viewPort)
        if (viewBox != Box(0.0, 0.0, 0.0, 0.0)) {
            this.canvas.concat(calculateViewBoxTransform(this.state.viewPort, viewBox, positioning()))
            this.state.viewBox = obj.viewBox
        } else {
            this.canvas.translate(this.state.viewPort.minX, this.state.viewPort.minY, Paint(Option<Paint>.None))
        }
        let compositing: Bool = pushLayer()
        viewportFill()

        renderChildren(obj, true, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func updateStyleForElement(state: RendererState, obj: SvgElementBase): Unit {
        let isRootSVG: Bool = obj.parent.isNone()
        state.style.resetNonInheritingProperties(isRootSVG)
        updateStyle(state, obj.baseStyle)
        if (let Some(v) <- this.document) {
            if (v.hasCSSRules()) {
                for (i in 0..v.getCSSRules().size) {
                    if (CSSParser.ruleMatch(this.ruleMatchContext, v.getCSSRules()[i].selector, obj)) {
                        updateStyle(state, v.getCSSRules()[i].style)
                    }
                }
            }
        }
        if (let Some(s) <- obj.style) {
            updateStyle(state, s)
        }
    }

    private func display(): Bool {
        return this.state.style.display
    }

    private func setClipRect(minX: Float64, minY: Float64, width: Float64, height: Float64): Unit {
        var left = minX
        var top = minY
        var right = minX + width
        var bottom = minY + height
        if (let Some(v) <- this.state.style.clip) {
            left += v.left.floatValueX(this)
            top += v.top.floatValueY(this)
            right -= v.right.floatValueX(this)
            bottom -= v.bottom.floatValueY(this)
        }
        this.canvas.clipRect(left, top, right, bottom)
    }

    private func checkForClipPath(obj: SvgElement, boundingBox!: Box = obj.boundingBox): Unit {
        if (this.state.style.clipPath.isEmpty()) {
            return
        }
        let combinedPath: ?Path2D = calculateClipPath(obj, boundingBox)
        if (let Some(v) <- combinedPath) {
            this.combinedPath = v
            this.canvas.clipPath(v)
        }
    }

    private func calculateClipPath(obj: SvgElement, boundingBox: Box): ?Path2D {
        let ref: SvgObject = obj.document().resolveIRI(this.state.style.clipPath) ?? return None
        let clipPath: ClipPath = (ref as ClipPath)()
        this.stateStack.addLast(this.state)
        this.state = findInheritFromAncestorState(clipPath)
        let userUnits: Bool = (clipPath.clipPathUnitsAreUser == false || clipPath.clipPathUnitsAreUser)
        let m: Matrix2D2 = Matrix2D2()
        if (!userUnits) {
            m.translate(boundingBox.minX, y: boundingBox.minY)
            m.scale(boundingBox.width, y: boundingBox.height)
        }
        if (let Some(v) <- clipPath.transform) {
            m.append(v.a, v.b, v.c, v.d, v.tx, v.ty)
        }
        var cp: Path2D = Path2D()
        for (i in 0..clipPath.children.size) {
            let child = clipPath.children[i]
            if (let Some(ele) <- (child as SvgElement)) {
                cp = objectToPath(ele, true)
            } else {
                continue
            }
        }
        if (!this.state.style.clipPath.isEmpty()) {
            let clipClipPath: ?Path2D = calculateClipPath(clipPath, clipPath.boundingBox)
            if (let Some(v) <- clipClipPath) {
                cp.addPath(v)
            }
        }
        this.canvas.getContext().transform(m.a, m.b, m.c, m.d, m.getE(), m.getF())
        this.state = this.stateStack.removeLast() ?? RendererState(Option<RendererState>.None)
        return cp
    }

    private func calculateViewBoxTransform(viewPort: Box, viewBox: Box, positioning: PreserveAspectRatio): Matrix2D2 {
        let m: Matrix2D2 = Matrix2D2()
        if (positioning.getAlignment() == "") {
            return m
        }
        let xScale = viewPort.width / viewBox.width
        let yScale = viewPort.height / viewBox.height
        var xOffset = -viewBox.minX
        var yOffset = -viewBox.minY
        if (positioning == PreserveAspectRatio.STRETCH) {
            m.translate(viewPort.minX, y: viewPort.minY)
            m.scale(xScale, y: yScale)
            m.translate(xOffset, y: yOffset)
            return m
        }
        let scale = if (positioning.getScale() == Scale.slice) {
            max(xScale, yScale)
        } else {
            min(xScale, yScale)
        }
        let imageW = viewPort.width / scale
        let imageH = viewPort.height / scale
        if (positioning.getAlignment() != "") {
            if (positioning.getAlignment() == Alignment.xMidYMin) {
            } else if (positioning.getAlignment() == Alignment.xMidYMid) {
            } else if (positioning.getAlignment() == Alignment.xMidYMax) {
                xOffset -= (viewBox.width - imageW) / 2.0
            } else if (positioning.getAlignment() == Alignment.xMaxYMin) {}
            else if (positioning.getAlignment() == Alignment.xMaxYMid) {}
            else if (positioning.getAlignment() == Alignment.xMaxYMax) {
                xOffset -= (viewBox.width - imageW)
            } else {
            }
        }

        if (positioning.getAlignment() != "") {
            if (positioning.getAlignment() == Alignment.xMinYMid) {
            } else if (positioning.getAlignment() == Alignment.xMidYMid) {}
            else if (positioning.getAlignment() == Alignment.xMaxYMid) {
                yOffset -= (viewBox.height - imageH) / 2.0
            } else if (positioning.getAlignment() == Alignment.xMinYMax) {}
            else if (positioning.getAlignment() == Alignment.xMidYMax) {}
            else if (positioning.getAlignment() == Alignment.xMaxYMax) {
                yOffset -= (viewBox.height - imageH)
            } else {
            }
        }
        m.translate(viewPort.minX, y: viewPort.minY)
        m.scale(scale, y: scale)
        m.translate(xOffset, y: yOffset)
        return m
    }

    private func pushLayer(o!: Float64 = 1.0): Bool {
        var opacityAdjustment = o
        if (this.state.style.fillOpacity != 1.0) {
            this.canvas.getContext().globalAlpha(this.state.style.fillOpacity)
        }
        if (opacityAdjustment != 1.0) {
            this.canvas.getContext().globalAlpha(opacityAdjustment)
        }
        if (!requiresCompositing() && opacityAdjustment == 1.0) {
            return false
        }
        if (this.state.style.opacity != 1.0) {
            this.canvas.getContext().globalAlpha(this.state.style.opacity)
        }
        this.stateStack.addLast(this.state)
        this.state = RendererState(this.state)
        if (this.state.style.mask != "") {
            let ref: ?SvgObject = this.document().resolveIRI(this.state.style.mask)
            if (let Some(v) <- ref) {
                if (!(v is Mask)) {
                    this.state.style.mask = ""
                    return true
                }
            }
        }
        return true
    }

    private func requiresCompositing(): Bool {
        return (this.state.style.opacity < 1.0) || (this.state.style.mask != "") || (this.state.style.isolation ==
            Isolation().isolate)
    }

    private func viewportFill(): Unit {
        var col: Color
        if (let Some(colo) <- (this.state.style.viewportFill as Colour)) {
            col = colo.colour
        } else if (let Some(current) <- (this.state.style.viewportFill as CurrentColor)) {
            col = this.state.style.color.colour
        } else {
            return
        }
        if (!this.state.style.viewportFillOpacity.isNaN()) {
            this.canvas.drawColor(col)
        }
    }

    private func renderChildren(obj: SvgContainer, isContainer: Bool, context: ?AbilityContext): Unit {
        if (isContainer) {
            parentPush(obj)
        }
        for (i in 0..obj.getChildren().size) {
            let child = obj.getChildren()[i]
            render(child, context)
        }
        if (isContainer) {
            parentPop()
        }
    }

    private func parentPush(obj: SvgContainer): Unit {
        this.parentStack.addLast(obj)
        this.matrixStack.addLast(this.canvas.getMatrix())
    }

    private func parentPop(): Unit {
        this.parentStack.removeLast()
        this.matrixStack.removeLast()
    }

    private func render(obj: SvgObject, context: ?AbilityContext): Unit {
        if (!obj.isRender) {
            return
        }
        statePush()
        checkXMLSpaceAttribute(obj)
        if (let Some(svg) <- (obj as Svg)) {
            renderSvg(svg, Option<Box>.None, context)
        } else if (let Some(use) <- (obj as Use)) {
            renderUse(use, context)
        } else if (let Some(switch) <- (obj as Switch)) {
            renderSwitch(switch, context)
        } else if (let Some(group) <- (obj as Group)) {
            renderGroup(group, context)
        } else if (let Some(image) <- (obj as Image2)) {
            renderImage(image, context)
        } else if (let Some(path) <- (obj as Path2)) {
            renderPath(path, context)
        } else if (let Some(rect) <- (obj as Rect2)) {
            renderRect(rect, context)
        } else if (let Some(circle) <- (obj as Circle2)) {
            renderCircle(circle, context)
        } else if (let Some(ellipse) <- (obj as Ellipse2)) {
            renderEllipse(ellipse, context)
        } else if (let Some(line) <- (obj as Line2)) {
            renderLine(line, context)
        } else if (let Some(polygon) <- (obj as Polygon2)) {
            renderPolygon(polygon, context)
        } else if (let Some(polyLine) <- (obj as PolyLine)) {
            renderPolyLine(polyLine, context)
        } else if (let Some(text) <- (obj as Text2)) {
            renderText(text, context)
        }
        statePop()
    }

    private func popLayer(obj: SvgElement, context: ?AbilityContext, originalObjBBox!: Box = obj.boundingBox): Unit {
        if (this.state.style.mask != "") {
            this.canvas.getContext().globalCompositeOperation(CompositeOperation.DestinationIn)
            let ref: ?SvgObject = this.document().resolveIRI(this.state.style.mask)
            if (let Some(v) <- ref) {
                if (let Some(ref) <- (v as Mask)) {
                    renderMask(ref, obj, context, originalObjBBox: originalObjBBox)
                }
            }
            // The retore composites the luminanceToAlpha layer with the masks alpha
            this.canvas.restore()

            // Apply the final mask to the original object waiting in the open layer created in pushLayer()
            this.canvas.restore()
        }
        statePop()
        this.canvas.restore()
    }

    private func renderMask(mask: Mask, obj: SvgElement, context: ?AbilityContext,
        originalObjBBox!: Box = Box(0.0, 0.0, 200.0, 200.0)): Unit {
        let maskUnitsAreUser: Bool = mask.maskUnitsAreUser
        var w: Float64 = 0.0
        var h: Float64 = 0.0
        if (maskUnitsAreUser) {
            w = if (!mask.width.isZero()) {
                mask.width.floatValueX(this)
            } else {
                originalObjBBox.width
            }
            h = if (!mask.height.isZero()) {
                mask.width.floatValueY(this)
            } else {
                originalObjBBox.height
            }
        } else {
            w = if (!mask.width.isZero()) {
                mask.width.floatValue(this, max: 1.0)
            } else {
                1.2
            }
            h = if (!mask.height.isZero()) {
                mask.height.floatValue(this, max: 1.0)
            } else {
                1.2
            }
            w *= originalObjBBox.width
            h *= originalObjBBox.height
        }
        if (w == 0.0 || h == 0.0) {
            return
        }
        statePush()
        this.state = findInheritFromAncestorState(mask)
        this.state.style.opacity = 1.0
        let compositing: Bool = pushLayer()
        this.canvas.save()
        let maskContentUnitsAreUser: Bool = if (mask.maskContentUnitsAreUser.isNone()) {
            true
        } else {
            mask.maskContentUnitsAreUser()
        }
        if (!maskContentUnitsAreUser) {
            this.canvas.translate(originalObjBBox.minX, originalObjBBox.minY, Paint(Option<Paint>.None))
            this.canvas.scale(originalObjBBox.width, originalObjBBox.height, Paint(Option<Paint>.None))
        }
        renderChildren(mask, false, context)
        this.canvas.restore()
        if (compositing) {
            popLayer(obj, context, originalObjBBox: originalObjBBox)
        }
        statePop()
    }

    private func findInheritFromAncestorState(
        o: SvgObject,
        n!: RendererState = RendererState(Option<RendererState>.None)
    ): RendererState {
        var obj: SvgObject = o
        var newState: RendererState = n
        updateStyle(newState, Style.getDefaultStyle())
        let ancestors: ArrayList<SvgElementBase> = ArrayList<SvgElementBase>()
        while (true) {
            if (obj is SvgElementBase) {
                ancestors.add((obj as SvgElementBase)(), at: 0)
            }
            if (obj.parent.isNone()) {
                break
            }
            obj = (obj.parent.getOrThrow() as SvgObject)()
        }
        for (i in 0..ancestors.size) {
            let ancestor = ancestors[i]
            updateStyleForElement(newState, ancestor)
        }
        newState.viewBox = this.state.viewBox
        newState.viewPort = this.state.viewPort
        return newState
    }

    private func renderPath(obj: Path2, context: ?AbilityContext): Unit {
        if (obj.d.isNone()) {
            return
        }
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (!this.state.hasStroke && !this.state.hasFill) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        let path: Path2D = Path2D(obj.d().d)
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        if (this.state.hasStroke) {
            doStroke(path)
        }
        if (this.state.hasFill) {
            doFilledPath(obj, path, context)
            renderMarkers(obj, context)
        }
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func visible(): Bool {
        return this.state.style.visibility
    }

    private func checkForGradientsAndPatterns(obj: SvgElement): Unit {
        if (let Some(v) <- this.state.style.fill) {
            if (v is PaintReference) {
                decodePaintReference(true, obj.boundingBox, (v as PaintReference).getOrThrow())
            }
        }
        if (let Some(j) <- this.state.style.stroke) {
            if (j is PaintReference) {
                decodePaintReference(true, obj.boundingBox, (j as PaintReference).getOrThrow())
            }
        }
    }

    private func decodePaintReference(isFill: Bool, boundingBox: Box, paintref: PaintReference): Unit {
        let ref: ?SvgObject = this.document().resolveIRI(paintref.href)
        if (ref.isNone()) {
            if (let Some(v) <- paintref.fallback) {
                setPaintColour(this.state, isFill, v)
            } else {
                if (isFill) {
                    this.state.hasFill = false
                } else {
                    this.state.hasStroke = false
                }
            }
            return
        }
        if (let Some(svgLinearGradient) <- (ref() as SvgLinearGradient)) {
            makeLinearGradient(isFill, boundingBox, svgLinearGradient)
        } else if (let Some(svgRadialGradient) <- (ref() as SvgRadialGradient)) {
            makeRadialGradient(isFill, boundingBox, svgRadialGradient)
        } else if (let Some(solidColor) <- (ref() as SolidColor)) {
            setSolidColor(isFill, solidColor)
        }
    }

    private func makeLinearGradient(isFill: Bool, boundingBox: Box, gradient: SvgLinearGradient): Unit {
        if (gradient.href != "") {
            fillInChainedGradientFields(gradient, gradient.href)
        }
        let userUnits: Bool = gradient.gradientUnitsAreUser
        let paint: Paint = if (isFill) {
            this.state.fillPaint
        } else {
            this.state.strokePaint
        }
        var _x1: Float64
        var _y1: Float64
        var _x2: Float64
        var _y2: Float64
        if (userUnits) {
            let viewPortUser: Box = getCurrentViewPortInUserUnits()
            _x1 = gradient.x1.floatValueX(this)
            _y1 = gradient.y1.floatValueY(this)
            _x2 = if (!gradient.x2.isZero()) {
                gradient.x2.floatValueX(this)
            } else {
                viewPortUser.width
            }
            _y2 = gradient.y2.floatValueY(this)
        } else {
            _x1 = gradient.x1.floatValue(this, max: 1.0)
            _y1 = gradient.y1.floatValue(this, max: 1.0)
            _x2 = gradient.x2.floatValue(this, max: 1.0)
            _y2 = gradient.y2.floatValue(this, max: 1.0)
        }
        statePush()
        this.state = findInheritFromAncestorState(gradient)
        let m: Matrix2D2 = Matrix2D2()
        if (!userUnits && boundingBox != Box(0.0, 0.0, 0.0, 0.0)) {
            m.translate(boundingBox.minX, y: boundingBox.minY)
            m.scale(boundingBox.width, y: boundingBox.height)
        }
        if (let Some(v) <- gradient.gradientTransform) {
            m.append(v.a, v.b, v.c, v.d, v.tx, v.ty)
        }
        let numStops = gradient.children.size
        if (numStops == 0) {
            statePop()
            if (isFill) {
                this.state.hasFill = false
            } else {
                this.state.hasStroke = false
            }
            return
        }
        let colours: ArrayList<Color> = ArrayList<Color>(numStops)
        let positions: ArrayList<Int64> = ArrayList<Int64>(numStops)
        var lastOffset: Int64 = -1
        var i: Int64 = 0
        for (j in 0..gradient.children.size) {
            let stop: Stop = (gradient.children[j] as Stop)()
            let offset: Int64 = if (stop.offset != 0) {
                stop.offset
            } else {
                0
            }
            if (i == 0 || offset >= lastOffset) {
                positions.add(offset, at: i)
                lastOffset = offset
            } else {
                positions.add(lastOffset, at: i)
            }
            statePush()
            updateStyleForElement(this.state, stop)
            var col: Colour = if (let Some(stopColor) <- (this.state.style.stopColor as Colour)) {
                stopColor
            } else {
                Colour.BLACK
            }
            colours.add(col.colour, at: i)
            i++
            statePop()
        }
        if ((_x1 == _x2 && _y1 == _y2) || numStops == 1) {
            statePop()
            paint.setColor(colours[numStops - 1])
            return
        }
        statePop()
        let gr: CanvasGradient = this.canvas.getContext().createLinearGradient(_x1, _y1, _x2, _y2)
        for (i in 0..positions.size) {
            gr.addColorStop(positions[i], colours[i])
        }
        this.state.fillPaint.setGradient(gr)
        this.canvas.getContext().globalAlpha(this.state.style.fillOpacity)
        paint.setAlpha(SVGRenderer.clamp255(this.state.style.fillOpacity))
    }

    private func fillInChainedGradientFields(gradient: GradientElement, href: String): Unit {
        let ref: ?SvgObject = gradient.document().resolveIRI(href)
        if (let Some(v) <- ref) {
            if (!(v is GradientElement) || (v as GradientElement)() == gradient) {
                return
            }
            let grRef = (ref as GradientElement)()
            if (gradient.gradientUnitsAreUser == false) {
                gradient.gradientUnitsAreUser = grRef.gradientUnitsAreUser
            }
            if (gradient.gradientTransform.isNone()) {
                gradient.gradientTransform = grRef.gradientTransform
            }
            if (gradient.spreadMethod == GradientSpread()) {
                gradient.spreadMethod = grRef.spreadMethod
            }
            if (gradient.children.size == 0) {
                gradient.children = grRef.children
            }
            try {
                if (gradient is SvgLinearGradient) {
                    fillInChainedGradientFields2((gradient as SvgLinearGradient)(), (ref as SvgLinearGradient)())
                } else {
                    fillInChainedGradientFields3((gradient as SvgRadialGradient)(), (ref as SvgRadialGradient)())
                }
            } catch (e: Exception) {
            }
            if (grRef.href != "") {
                fillInChainedGradientFields(gradient, grRef.href)
            }
        } else {
            return
        }
    }

    private func fillInChainedGradientFields2(gradient: SvgLinearGradient, grRef: SvgLinearGradient): Unit {
        if (gradient.x1.isZero()) {
            gradient.x1 = grRef.x1
        }
        if (gradient.y1.isZero()) {
            gradient.y1 = grRef.y1
        }
        if (gradient.x2.isZero()) {
            gradient.x2 = grRef.x2
        }
        if (gradient.y2.isZero()) {
            gradient.y2 = grRef.y2
        }
    }

    private func fillInChainedGradientFields3(gradient: SvgRadialGradient, grRef: SvgRadialGradient): Unit {
        if (gradient.cx.isZero()) {
            gradient.cx = grRef.cx
        }
        if (gradient.cy.isZero()) {
            gradient.cy = grRef.cy
        }
        if (gradient.r.isZero()) {
            gradient.r = grRef.r
        }
        if (gradient.fx.isZero()) {
            gradient.fx = grRef.fx
        }
        if (gradient.fy.isZero()) {
            gradient.fy = grRef.fy
        }
    }

    private static func clamp255(val: Float64): Float64 {
        let i = val * 256.0
        return if (i < 0.0) {
            0.0
        } else {
            min(i, 255.0)
        }
    }

    private func makeRadialGradient(isFill: Bool, boundingBox: Box, gradient: SvgRadialGradient): Unit {
        if (gradient.href != "") {
            fillInChainedGradientFields(gradient, gradient.href)
        }
        let userUnits: Bool = gradient.gradientUnitsAreUser
        let paint: Paint = if (isFill) {
            this.state.fillPaint
        } else {
            this.state.strokePaint
        }
        var _cx: Float64
        var _cy: Float64
        var _r: Float64
        var _fx: Float64
        var _fy: Float64
        if (userUnits) {
            let fiftyPercent: SVGLength = SVGLength(50.0, u: Units.percent)
            _cx = if (!gradient.cx.isZero()) {
                gradient.cx.floatValueX(this)
            } else {
                fiftyPercent.floatValueX(this)
            }
            _cy = if (!gradient.cy.isZero()) {
                gradient.cy.floatValueY(this)
            } else {
                fiftyPercent.floatValueY(this)
            }
            _r = if (!gradient.r.isZero()) {
                gradient.r.floatValue(this)
            } else {
                fiftyPercent.floatValue(this)
            }
        } else {
            _cx = if (!gradient.cx.isZero()) {
                gradient.cx.floatValue(this, max: 1.0)
            } else {
                0.5
            }
            _cy = if (!gradient.cy.isZero()) {
                gradient.cy.floatValue(this, max: 1.0)
            } else {
                0.5
            }
            _r = if (!gradient.r.isZero()) {
                gradient.r.floatValue(this, max: 1.0)
            } else {
                0.5
            }
        }
        statePush()
        this.state = findInheritFromAncestorState(gradient)
        let m = Matrix2D2()
        if (!userUnits) {
            m.translate(boundingBox.minX, y: boundingBox.minY)
            m.scale(boundingBox.width, y: boundingBox.height)
        }
        if (let Some(v) <- gradient.gradientTransform) {
            m.append(v.a, v.b, v.c, v.d, v.tx, v.ty)
        }
        let numStops = gradient.children.size
        if (numStops == 0) {
            statePop()
            if (isFill) {
                this.state.hasFill = false
            } else {
                this.state.hasStroke = false
            }
            return
        }
        let colours: ArrayList<Color> = ArrayList<Color>(numStops)
        let positions: ArrayList<Int64> = ArrayList<Int64>(numStops)
        var i: Int64 = 0
        var lastOffset: Int64 = -1
        for (j in 0..gradient.children.size) {
            let child = gradient.children[j]
            let stop = (child as Stop)()
            let offset = if (stop.offset != 0) {
                stop.offset
            } else {
                0
            }
            if (i == 0 || offset >= lastOffset) {
                positions.add(offset, at: i)
                lastOffset = offset
            } else {
                positions.add(lastOffset, at: i)
            }
            statePush()
            updateStyleForElement(this.state, stop)
            var col = this.state.style.stopColor as Colour
            if (col.isNone()) {
                col = Colour.BLACK
            }
            colours.add(col().colour, at: i)
            i++
            statePop()
        }
        if (_r == 0.0 || numStops == 1) {
            statePop()
            paint.setColor(colours[numStops - 1])
            return
        }
        statePop()
        let gr: CanvasGradient = this.canvas.getContext().createRadialGradient(_cx, _cy, _r, 0.0, 0.0, 0.0)
        for (i in 0..positions.size) {
            gr.addColorStop(positions[i], colours[i])
        }
        this.state.fillPaint.setGradient(gr)
        this.canvas.getContext().globalAlpha(this.state.style.fillOpacity)
        paint.setAlpha(SVGRenderer.clamp255(this.state.style.fillOpacity))
    }

    private func setSolidColor(isFill: Bool, ref: SolidColor): Unit {
        if (isFill) {
            if (isSpecified(ref.baseStyle, Style.SPECIFIED_SOLID_COLOR)) {
                this.state.style.fill = ref.baseStyle.solidColor
                this.state.hasFill = (ref.baseStyle.solidColor.isSome())
            }
            if (isSpecified(ref.baseStyle, Style.SPECIFIED_SOLID_OPACITY)) {
                this.state.style.fillOpacity = ref.baseStyle.solidOpacity
            }
            if (isSpecified(ref.baseStyle, Style.SPECIFIED_SOLID_COLOR | Style.SPECIFIED_SOLID_OPACITY)) {
                if (let Some(v) <- this.state.style.fill) {
                    setPaintColour(this.state, isFill, v)
                }
            }
        } else {
            if (isSpecified(ref.baseStyle, Style.SPECIFIED_SOLID_COLOR)) {
                this.state.style.stroke = ref.baseStyle.solidColor
                this.state.hasStroke = (ref.baseStyle.solidColor.isSome())
            }
            if (isSpecified(ref.baseStyle, Style.SPECIFIED_SOLID_OPACITY)) {
                this.state.style.strokeOpacity = ref.baseStyle.solidOpacity
            }
            if (isSpecified(ref.baseStyle, Style.SPECIFIED_SOLID_COLOR | Style.SPECIFIED_SOLID_OPACITY)) {
                if (let Some(v) <- this.state.style.stroke) {
                    setPaintColour(this.state, isFill, v)
                }
            }
        }
    }

    private func renderMarkers(obj: GraphicsElement, context: ?AbilityContext): Unit {
        if (this.state.style.markerStart == "" && this.state.style.markerMid == "" && this.state.style.markerEnd == "") {
            return
        }
        var _markerStart: ?Marker = None
        var _markerMid: ?Marker = None
        var _markerEnd: ?Marker = None

        if (this.state.style.markerStart != "") {
            let ref: ?SvgObject = obj.document().resolveIRI(this.state.style.markerStart)
            if (let Some(v) <- ref) {
                _markerStart = v as Marker
            }
        }
        if (this.state.style.markerMid != "") {
            let ref: ?SvgObject = obj.document().resolveIRI(this.state.style.markerMid)
            if (let Some(v) <- ref) {
                _markerMid = v as Marker
            }
        }

        if (this.state.style.markerEnd != "") {
            let ref: ?SvgObject = obj.document().resolveIRI(this.state.style.markerEnd)
            if (let Some(v) <- ref) {
                _markerEnd = v as Marker
            }
        }
        var markers: ArrayList<MarkerVector>
        match (obj) {
            case v: Path2 => markers = (MarkerPositionCalculator(v.d)).getMarkers()
            case v: Line2 => markers = calculateMarkerPositionsLine(v)
            case _ => markers = calculateMarkerPositionsPolyLine((obj as PolyLine)())
        }

        if (markers.isEmpty()) {
            return
        }
        let markerCount = markers.size
        if (markerCount == 0) {
            return
        }
        this.state.style.markerStart = ""
        this.state.style.markerMid = ""
        this.state.style.markerEnd = ""
        if (let Some(v) <- _markerStart) {
            renderMarker(v, markers[0], context)
        }
        if (_markerMid.isSome() && markers.size > 2) {
            var lastPos: MarkerVector = markers[0]
            var thisPos: MarkerVector = markers[1]
            for (i in 1..(markerCount - 1)) {
                let nextPos: MarkerVector = markers[i + 1]
                if (thisPos.isAmbiguous) {
                    thisPos = realignMarkerMid(lastPos, thisPos, nextPos)
                }
                renderMarker(_markerMid(), thisPos, context)
                lastPos = thisPos
                thisPos = nextPos
            }
        }

        if (let Some(v) <- _markerEnd) {
            renderMarker(v, markers[markerCount - 1], context)
        }
    }

    private func doFilledPath(obj: SvgElement, path: Path2D, context: ?AbilityContext): Unit {
        if (let Some(v) <- this.state.style.fill) {
            if (v is PaintReference) {
                let fill = (v as PaintReference)()
                let ref: ?SvgObject = this.document().resolveIRI(fill.href)
                if (let Some(j) <- ref) {
                    if (let Some(ref) <- (j as Pattern)) {
                        let pattern: Pattern = ref
                        fillWithPattern(obj, path, pattern, context)
                        return
                    }
                }
            }
        }
        this.canvas.drawPath(path, this.state.fillPaint)
    }

    private func fillWithPattern(obj: SvgElement, path: Path2D, pattern: Pattern, context: ?AbilityContext): Unit {
        let patternUnitsAreUser: Bool = pattern.patternUnitsAreUser
        var x: Float64 = 0.0
        var y: Float64 = 0.0
        var w: Float64 = 0.0
        var h: Float64 = 0.0
        var originX: Float64 = 0.0
        var originY: Float64 = 0.0
        let objFillOpacity: Float64 = this.state.style.fillOpacity
        if (pattern.href != "") {
            fillInChainedPatternFields(pattern, pattern.href)
        }
        if (patternUnitsAreUser) {
            x = pattern.x.floatValueX(this)
            y = pattern.y.floatValueY(this)
            w = pattern.width.floatValueX(this)
            h = pattern.height.floatValueY(this)
        } else {
            x = pattern.x.floatValue(this, max: 1.0)
            y = pattern.y.floatValue(this, max: 1.0)
            w = pattern.width.floatValue(this, max: 1.0)
            h = pattern.height.floatValue(this, max: 1.0)
            x = obj.boundingBox.minX + x * obj.boundingBox.width
            y = obj.boundingBox.minY + y * obj.boundingBox.height
            w *= obj.boundingBox.width
            h *= obj.boundingBox.height
        }
        if (w == 0.0 || h == 0.0) {
            return
        }
        let positioning: PreserveAspectRatio = if (let Some(v) <- pattern.preserveAspectRatio) {
            v
        } else {
            PreserveAspectRatio.LETTERBOX
        }
        statePush()
        this.canvas.clipPath(path)
        let baseState: RendererState = RendererState(Option<RendererState>.None)
        updateStyle(baseState, Style.getDefaultStyle())
        baseState.style.overflow = false
        this.state = findInheritFromAncestorState(pattern, n: baseState)
        let patternArea: Box = obj.boundingBox
        if (let Some(v) <- pattern.patternTransform) {
            this.canvas.concat(v)
        }
        originX = x + round((patternArea.minX - x) / w) * w
        originY = y + round((patternArea.minY - y) / h) * h
        let right: Float64 = patternArea.maxX()
        let bottom: Float64 = patternArea.maxY()
        let stepViewBox: Box = Box(0.0, 0.0, w, h)
        let compositing: Bool = pushLayer(o: objFillOpacity)
        var stepY: Float64 = originY
        while (stepY < bottom) {
            var stepX = originX
            while (stepX < right) {
                stepViewBox.minX = stepX
                stepViewBox.minY = stepY
                statePush()
                if (!this.state.style.overflow) {
                    setClipRect(stepViewBox.minX, stepViewBox.minY, stepViewBox.width, stepViewBox.height)
                }
                if (pattern.viewBox != Box(0.0, 0.0, 0.0, 0.0)) {
                    this.canvas.concat(calculateViewBoxTransform(stepViewBox, pattern.viewBox, positioning))
                } else {
                    let patternContentUnitsAreUser: Bool = pattern.patternContentUnitsAreUser
                    this.canvas.translate(stepX, stepY, Paint(Option<Paint>.None))
                    if (!patternContentUnitsAreUser) {
                        this.canvas.scale(obj.boundingBox.width, obj.boundingBox.height, Paint(Option<Paint>.None))
                    }
                }
                for (i in 0..pattern.children.size) {
                    let child = pattern.children[i]
                    render(child, context)
                }
                statePop()
                stepX += w
            }
            stepY += h
        }
        if (compositing) {
            popLayer(pattern, context)
        }
        statePop()
    }

    private func fillInChainedPatternFields(p: Pattern, href: String): Unit {
        var pattern = p
        let ref: ?SvgObject = pattern.document().resolveIRI(href)
        if (let Some(v) <- ref) {
            if (!(v is Pattern) || (v as Pattern)() == pattern) {
                return
            }
            let pRef: Pattern = (v as Pattern)()
            if (pattern.patternUnitsAreUser == false) {
                pattern.patternUnitsAreUser = pRef.patternUnitsAreUser
            }
            if (pattern.patternContentUnitsAreUser == false) {
                pattern.patternContentUnitsAreUser = pRef.patternContentUnitsAreUser
            }
            if (pattern.patternTransform.isNone()) {
                pattern.patternTransform = pRef.patternTransform
            }
            if (pattern.x.isZero()) {
                pattern.x = pRef.x
            }
            if (pattern.y.isZero()) {
                pattern.y = pRef.y
            }
            if (pattern.width.isZero()) {
                pattern.width = pRef.width
            }
            if (pattern.height.isZero()) {
                pattern.height = pRef.height
            }
            if (pattern.children.size == 0) {
                pattern.children = pRef.children
            }
            if (pattern.viewBox == Box(0.0, 0.0, 0.0, 0.0)) {
                pattern.viewBox = pRef.viewBox
            }
            if (pattern.preserveAspectRatio.isNone()) {
                pattern.preserveAspectRatio = pRef.preserveAspectRatio
            }
            if (pRef.href != "") {
                fillInChainedPatternFields(pattern, pRef.href)
            }
        } else {
            return
        }
    }

    private func doStroke(path: Path2D): Unit {
        if (this.state.style.vectorEffect == VectorEffect().NonScalingStroke) {
            let currentMatrix: Matrix2D2 = this.canvas.getMatrix()
            let transformedPath: Path2D = Path2D()
            this.canvas.setMatrix(Matrix2D2())
            this.canvas.drawPath(transformedPath, this.state.strokePaint)
            this.canvas.setMatrix(currentMatrix)
        } else {
            this.canvas.drawPath(path, this.state.strokePaint)
        }
    }

    private func renderRect(obj: Rect2, context: ?AbilityContext): Unit {
        if (obj.width.isZero() || obj.height.isZero()) {
            return
        }
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        if (this.combinedPath.isSome()) {
            obj.x = SVGLength()
            obj.y = SVGLength()
            obj.width = SVGLength(2000.0)
            obj.height = SVGLength(2000.0)
        }
        let path: Path2D = makePathAndBoundingBoxRect(obj)
        let compositing: Bool = pushLayer()
        if (this.state.hasFill) {
            doFilledPath(obj, path, context)
        }
        if (this.state.hasStroke) {
            doStroke(path)
        }
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderCircle(obj: Circle2, context: ?AbilityContext): Unit {
        if (obj.r.isZero()) {
            return
        }
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        let path: Path2D = makePathAndBoundingBoxCircle(obj)
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        if (this.state.hasFill) {
            doFilledPath(obj, path, context)
        }
        if (this.state.hasStroke) {
            doStroke(path)
        }
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderEllipse(obj: Ellipse2, context: ?AbilityContext): Unit {
        if (obj.rx.isZero() || obj.ry.isZero()) {
            return
        }
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (let Some(v) <- obj.transform) {
            canvas.concat(v)
        }
        let path = makePathAndBoundingBoxEllipse(obj)
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        if (this.state.hasFill) {
            doFilledPath(obj, path, context)
        }
        if (this.state.hasStroke) {
            doStroke(path)
        }
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderLine(obj: Line2, context: ?AbilityContext): Unit {
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (!this.state.hasStroke) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        let path: Path2D = makePathAndBoundingBoxLine(obj)
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        doStroke(path)
        renderMarkers(obj, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func calculateMarkerPositionsLine(obj: Line2): ArrayList<MarkerVector> {
        var _x1: Float64
        var _y1: Float64
        var _x2: Float64
        var _y2: Float64
        _x1 = if (obj.x1.isZero()) {
            0.0
        } else {
            obj.x1.floatValueX(this)
        }
        _y1 = if (obj.y1.isZero()) {
            0.0
        } else {
            obj.y1.floatValueY(this)
        }
        _x2 = if (obj.x2.isZero()) {
            0.0
        } else {
            obj.x2.floatValueX(this)
        }
        _y2 = if (obj.y2.isZero()) {
            0.0
        } else {
            obj.y2.floatValueY(this)
        }
        let markers: ArrayList<MarkerVector> = ArrayList<MarkerVector>()
        markers.add(MarkerVector(_x1, _y1, (_x2 - _x1), (_y2 - _y1)))
        markers.add(MarkerVector(_x2, _y2, (_x2 - _x1), (_y2 - _y1)))
        return markers
    }

    private func makePathAndBoundingBoxLine(obj: Line2): Path2D {
        let x1 = if (obj.x1.isZero()) {
            0.0
        } else {
            obj.x1.floatValueX(this)
        }
        let y1 = if (obj.y1.isZero()) {
            0.0
        } else {
            obj.y1.floatValueX(this)
        }
        let x2 = if (obj.x2.isZero()) {
            0.0
        } else {
            obj.x2.floatValueX(this)
        }
        let y2 = if (obj.y2.isZero()) {
            0.0
        } else {
            obj.y2.floatValueX(this)
        }
        if (obj.boundingBox == Box(0.0, 0.0, 0.0, 0.0)) {
            obj.boundingBox = Box(min(x1, x2), min(y1, y2), abs(x2 - x1), abs(y2 - y1))
        }
        let p: Path2D = Path2D()
        p.moveTo(x1, y1)
        p.lineTo(x2, y2)
        return p
    }

    private func renderPolyLine(obj: PolyLine, context: ?AbilityContext): Unit {
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (!this.state.hasStroke && !this.state.hasFill) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        let numPoints: Int64 = if (!obj.points.isEmpty()) {
            obj.points.size
        } else {
            0
        }
        if (numPoints < 2 || numPoints % 2 == 1) {
            return
        }
        let path: Path2D = makePathAndBoundingBoxPolyLine(obj)
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        if (this.state.hasFill) {
            doFilledPath(obj, path, context)
        }
        if (this.state.hasStroke) {
            doStroke(path)
        }
        renderMarkers(obj, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func calculateMarkerPositionsPolyLine(obj: PolyLine): ArrayList<MarkerVector> {
        let numPoints: Int64 = if (!(obj.points.isEmpty())) {
            obj.points.size
        } else {
            0
        }
        if (numPoints < 2) {
            return ArrayList<MarkerVector>()
        }
        let markers: ArrayList<MarkerVector> = ArrayList<MarkerVector>()
        var lastPos: MarkerVector = MarkerVector(obj.points[0], obj.points[1], 0.0, 0.0)
        var x: Float64 = 0.0
        var y: Float64 = 0.0
        for (i in 2..numPoints : 2) {
            x = obj.points[i]
            y = obj.points[i + 1]
            lastPos.add(x, y)
            markers.add(lastPos)
            lastPos = MarkerVector(x, y, x - lastPos.x, y - lastPos.y)
        }
        if (obj is Polygon2) {
            if (x != obj.points[0] && y != obj.points[1]) {
                x = obj.points[0]
                y = obj.points[1]
                lastPos.add(x, y)
                markers.add(lastPos)
                let newPos: MarkerVector = MarkerVector(x, y, x - lastPos.x, y - lastPos.y)
                newPos.add(markers[0].x, markers[0].y)
                markers.add(newPos)
                markers.remove(at: 0)
                markers.add(newPos, at: 0)
            }
        } else {
            markers.add(lastPos)
        }
        return markers
    }

    private func renderPolygon(obj: Polygon2, context: ?AbilityContext): Unit {
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (!this.state.hasStroke && !this.state.hasFill) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        let numPoints = if (!obj.points.isEmpty()) {
            obj.points.size
        } else {
            0
        }
        if (numPoints < 2) {
            return
        }
        let path: Path2D = makePathAndBoundingBoxPolyLine(obj)
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        if (this.state.hasFill) {
            doFilledPath(obj, path, context)
        }
        if (this.state.hasStroke) {
            doStroke(path)
        }
        renderMarkers(obj, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderText(obj: Text2, context: ?AbilityContext): Unit {
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (!visible()) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        let x = if (obj.x.isEmpty() || obj.x.size == 0) {
            0.0
        } else {
            obj.x[0].floatValueX(this)
        }
        let y = if (obj.y.isEmpty() || obj.y.size == 0) {
            0.0
        } else {
            obj.y[0].floatValueY(this)
        }
        let dx = if (obj.dx.isEmpty() || obj.dx.size == 0) {
            0.0
        } else {
            obj.dx[0].floatValueX(this)
        }
        let dy = if (obj.dy.isEmpty() || obj.dy.size == 0) {
            0.0
        } else {
            obj.dy[0].floatValueY(this)
        }
        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        let textAnchor: String = state.style.textAnchor.toAsciiLower()
        enumerateTextSpans(obj, PlainTextDrawer(x, y, dx, dy, textAnchor), context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func processTextChild(obj: SvgObject, textprocessor: TextProcessor, context: ?AbilityContext): Unit {
        if (!textprocessor.doTextContainer((obj as TextContainer)())) {
            return
        }
        if (obj is TextPath) {
            statePush()
            statePop()
        } else if (let Some(span) <- (obj as TSpan)) {
            statePush()
            let tspan = span
            updateStyleForElement(this.state, tspan)
            if (display()) {
                var x: Float64 = 0.0
                var y: Float64 = 0.0
                var dx: Float64 = 0.0
                var dy: Float64 = 0.0
                let specifiedX: Bool = (!tspan.x.isEmpty() && tspan.x.size > 0)
                if (specifiedX) {
                }
                checkForGradientsAndPatterns((tspan.getTextRoot() as SvgElement)())
                let compositing: Bool = pushLayer()
                enumerateTextSpans(tspan, textprocessor, context)
                if (compositing) {
                    popLayer(tspan, context)
                }
            }
            statePop()
        } else if (let Some(ref) <- (obj as TRef)) {
            statePush()
            let tref = ref
            updateStyleForElement(this.state, tref)
            if (display()) {
                checkForGradientsAndPatterns((tref.getTextRoot() as SvgElement)())
                let ref: ?SvgObject = obj.document().resolveIRI(tref.href)
                if (let Some(v) <- ref) {
                    if (let Some(ref) <- (v as TextContainer)) {
                        let str: String = ""
                        extractRawText(ref, str)
                        if (str.size > 0) {
                            textprocessor.processText(str.toString(), this.state, this.canvas)
                        }
                    }
                } else {}
            }
            statePop()
        } else if (let Some(t) <- (obj as Text2)) {
            statePush()
            updateStyleForElement(this.state, t)
            textprocessor.processText(textXMLSpaceTransform(t.text, true, true), this.state, this.canvas)
            statePop()
        }
    }

    private func extractRawText(parent: TextContainer, s: String): Unit {
        var str: String = s
        var isFirstChild: Bool = true
        for (i in 0..parent.children.size) {
            let child: SvgObject = parent.children[i]
            if (let Some(container) <- (child as TextContainer)) {
                extractRawText(container, str)
            } else if (let Some(sequence) <- (child as TextSequence)) {
                str += (textXMLSpaceTransform(sequence.text, isFirstChild, i + 1 != parent.children.size))
            }
            isFirstChild = false
        }
    }

    public static func arcTo(lastX: Float64, lastY: Float64, rX: Float64, rY: Float64, angle: Float64,
        largeArcFlag: Bool, sweepFlag: Bool, x: Float64, y: Float64, pather: PathInterface): Unit {
        var rx: Float64 = rX
        var ry: Float64 = rY
        if (lastX == x && lastY == y) {
            return
        }
        if (rx == 0.0 || ry == 0.0) {
            pather.lineTo(x, y)
            return
        }
        rx = abs(rx)
        ry = abs(ry)
        let angleRad: Float64 = Float64(Int64(angle) % 360) * Float64.PI / 180.0
        let cosAngle: Float64 = cos(angleRad)
        let sinAngle: Float64 = sin(angleRad)
        let dx2: Float64 = Float64(lastX - x) / 2.0
        let dy2: Float64 = Float64(lastY - y) / 2.0
        let x1: Float64 = cosAngle * dx2 + sinAngle * dy2
        let y1: Float64 = -sinAngle * dx2 + cosAngle * dy2
        var rx_sq: Float64 = Float64(rx * rx)
        var ry_sq: Float64 = Float64(ry * ry)
        let x1_sq: Float64 = x1 * x1
        let y1_sq: Float64 = y1 * y1
        let radiiCheck: Float64 = x1_sq / Float64(rx_sq) + y1_sq / Float64(ry_sq)
        if (radiiCheck > 0.99999) {
            let radiiScale: Float64 = sqrt(radiiCheck) * 1.00001
            rx = radiiScale * rx
            ry = radiiScale * ry
            rx_sq = rx * rx
            ry_sq = ry * ry
        }
        var sign: Float64 = if (largeArcFlag == sweepFlag) {
            -1.0
        } else {
            1.0
        }
        var sq: Float64 = ((rx_sq * ry_sq) - (rx_sq * y1_sq) - (ry_sq * x1_sq)) / ((rx_sq * y1_sq) + (ry_sq * x1_sq))
        sq = if (sq < 0.0) {
            0.0
        } else {
            sq
        }
        let coef: Float64 = (sign * sqrt(sq))
        let cx1: Float64 = (coef * ((rx * y1) / ry))
        let cy1: Float64 = (coef * -((ry * x1) / rx))
        let sx2: Float64 = Float64(lastX + x) / 2.0
        let sy2: Float64 = Float64(lastY + y) / 2.0
        let cx: Float64 = sx2 + (cosAngle * cx1 - sinAngle * cy1)
        let cy: Float64 = sy2 + (sinAngle * cx1 + cosAngle * cy1)
        let ux: Float64 = (x1 - cx1) / rx
        let uy: Float64 = (y1 - cy1) / ry
        let vx: Float64 = (-x1 - cx1) / rx
        let vy: Float64 = (-y1 - cy1) / ry
        var p: Float64
        var n: Float64
        let TWO_PI: Float64 = Float64.PI * 2.0
        n = sqrt((ux * ux) + (uy * uy))
        p = ux
        sign = if (uy < 0.0) {
            -1.0
        } else {
            1.0
        }
        var angleStart: Float64 = sign * acos(p / n)
        n = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
        p = ux * vx + uy * vy
        sign = if (ux * vy - uy * vx < 0.0) {
            -1.0
        } else {
            1.0
        }
        var angleExtent: Float64 = sign * checkedArcCos(p / n)
        if (angleExtent == 0.0) {
            pather.lineTo(x, y)
            return
        }
        if (!sweepFlag && angleExtent > 0.0) {
            angleExtent -= TWO_PI
        } else if (sweepFlag && angleExtent < 0.0) {
            angleExtent += TWO_PI
        }
        angleExtent = Float64(Int64(angleExtent) % Int64(TWO_PI))
        angleStart = Float64(Int64(angleStart) % Int64(TWO_PI))
        var bezierPoints = arcToBeziers(angleStart, angleExtent)
        let m = Matrix2D2()
        m.scale(rx, y: ry)
        m.rotate(Float64(angle))
        m.translate(cx, y: cy)
        m.append(bezierPoints[0], bezierPoints[1], bezierPoints[2], bezierPoints[3], bezierPoints[4], bezierPoints[5])
        bezierPoints[bezierPoints.size - 2] = x
        bezierPoints[bezierPoints.size - 1] = y
        for (i in 0..bezierPoints.size : 6) {
            pather.cubicTo(bezierPoints[i], bezierPoints[i + 1], bezierPoints[i + 2], bezierPoints[i + 3],
                bezierPoints[i + 4], bezierPoints[i + 5])
        }
    }

    private static func checkedArcCos(val: Float64): Float64 {
        return if (val < -1.0) {
            Float64.PI
        } else {
            if (val > 1.0) {
                0.0
            } else {
                acos(val)
            }
        }
    }

    private static func arcToBeziers(angleStart: Float64, angleExtent: Float64): ArrayList<Float64> {
        let numSegments: Float64 = ceil(abs(angleExtent) * 2.0 / Float64.PI)
        let angleIncrement: Float64 = angleExtent / numSegments
        let controlLength: Float64 = 4.0 / 3.0 * sin(angleIncrement / 2.0) / (1.0 + cos(angleIncrement / 2.0))
        let coords: ArrayList<Float64> = ArrayList<Float64>(Int64(numSegments) * 6)
        var pos: Int64 = 0
        for (i in 0..Int64(numSegments)) {
            var angle = angleStart + Float64(i) * angleIncrement
            var dx = cos(angle)
            var dy = sin(angle)
            coords.add(dx - controlLength * dy, at: pos)
            pos++
            coords.add(dy + controlLength * dx, at: pos)
            pos++
            angle += angleIncrement
            dx = cos(angle)
            dy = sin(angle)
            coords.add(dx + controlLength * dy, at: pos)
            pos++
            coords.add(dy - controlLength * dx, at: pos)
            pos++
            coords.add(dx, at: pos)
            pos++
            coords.add(dy, at: pos)
            pos++
        }
        return coords
    }

    private func enumerateTextSpans(obj: TextContainer, textprocessor: TextProcessor, context: ?AbilityContext): Unit {
        if (!display()) {
            return
        }
        var isFirstChild: Bool = true
        if (obj.children.size > 0) {
            for (i in 0..obj.children.size) {
                let child: SvgObject = obj.children[i]
                if (child is TextSequence) {
                    textprocessor.processText(
                        textXMLSpaceTransform((child as TextSequence)().text, isFirstChild, i + 1 != obj.children.size),
                        this.state, this.canvas)
                } else {
                    processTextChild(child, textprocessor, context)
                }
                isFirstChild = false
            }
        } else {
            if (obj is Text2) {
                textprocessor.processText(textXMLSpaceTransform((obj as Text2)().text, true, true), this.state,
                    this.canvas)
            } else if (obj is TSpan) {
                textprocessor.processText(textXMLSpaceTransform((obj as TSpan)().text, true, true), this.state,
                    this.canvas)
            }
        }
    }

    private func textXMLSpaceTransform(t: String, isFirstChild: Bool, isLastChild: Bool): String {
        var text: String = t
        if (this.state.spacePreserve) {
            return replaceTabsAndLineBreaks(text, " ")
        }
        text = replaceTabs(text, "")
        text = replaceLineBreaks(text, " ")
        if (isFirstChild) {
            text = replaceStartSpaces(text, "")
        }
        if (isLastChild) {
            text = replaceEndSpaces(text, "")
        }
        return replaceDoubleSpaces(text, " ")
    }

    private static func replaceTabsAndLineBreaks(text: String, replacement: String): String {
        let result: StringBuilder = StringBuilder()
        for (c in text.toRuneArray()) {
            if (c == r'\n' || c == r'\t') {
                result.append(replacement)
            } else {
                result.append(c)
            }
        }
        return result.toString()
    }

    private static func replaceTabs(text: String, replacement: String): String {
        return text.replace("\t", replacement)
    }

    private static func replaceLineBreaks(text: String, replacement: String): String {
        return text.replace("\n", replacement)
    }

    private static func replaceStartSpaces(text: String, replacement: String): String {
        var start: Int64 = 0
        while (start < text.size && text[start] == b' ') {
            start++
        }
        return replacement + text[start..]
    }

    private static func replaceEndSpaces(text: String, replacement: String): String {
        var end: Int64 = text.size
        while (end > 0 && text[end - 1] == b' ') {
            end--
        }
        return text[..end] + replacement
    }

    private static func replaceDoubleSpaces(text: String, replacement: String): String {
        let result: StringBuilder = StringBuilder()
        var inSpace: Bool = false
        for (c in text.toRuneArray()) {
            if (c == r' ') {
                if (!inSpace) {
                    result.append(replacement)
                    inSpace = true
                }
            } else {
                result.append(c)
                inSpace = false
            }
        }
        return result.toString()
    }

    private func renderImage(obj: Image2, context: ?AbilityContext): Unit {
        if (obj.width.isZero() || obj.height.isZero()) {
            return
        }
        if (obj.href == "") {
            return
        }
        let translateX = if (!obj.translateX.isZero()) {
            obj.translateX.floatValueX(this)
        } else {
            0.0
        }
        let translateY = if (!obj.translateY.isZero()) {
            obj.translateY.floatValueY(this)
        } else {
            0.0
        }
        let positioning: PreserveAspectRatio = if (let Some(v) <- obj.preserveAspectRatio) {
            v
        } else {
            PreserveAspectRatio.LETTERBOX
        }
        let pic: String = checkForImageDataURL(obj.href)
        if (pic == "") {
            let resourceManager = ResourceManager.getResourceManager(getStageContext(context()))
            let arr: Array<UInt8> = resourceManager.getRawFileContent(obj.href)
            let pixelMap: PixelMap = createImageSource(arr).createPixelMap()
            this.canvas.getContext().drawImage(pixelMap, translateX, translateY, obj.width.floatValue(this),
                obj.height.floatValue(this))
        } else {
            viewportFill()
            let array: Array<Byte> = fromBase64String(pic) ?? Array<Byte>(512, repeat: 0)
            let pixelMap: PixelMap = createImageSource(String.fromUtf8(array)).createPixelMap()
            if (!obj.x.isZero()) {
                this.canvas.getContext().drawImage(pixelMap, obj.x.floatValueX(this), obj.y.floatValueY(this),
                    obj.width.floatValue(this), obj.height.floatValue(this))
            } else {
                this.canvas.getContext().drawImage(pixelMap, 0.0, 0.0, obj.width.floatValue(this),
                    obj.height.floatValue(this))
            }
        }
    }

    private func checkForImageDataURL(url: String): String {
        if (!url.startsWith("data:")) {
            return ""
        }
        if (url.size < 14) {
            return ""
        }
        let comma: ?Int64 = url.indexOf(',')
        if (let Some(v) <- comma) {
            if (v < 12) {
                return ""
            }
            if ("base64" != url[(v - 7)..v]) {
                return ""
            }
            return url[(v + 1)..]
        } else {
            return ""
        }
    }

    private func renderGroup(obj: Group, context: ?AbilityContext): Unit {
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        renderChildren(obj, true, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderSwitch(obj: Switch, context: ?AbilityContext): Unit {
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        renderSwitchChild(obj, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderSwitchChild(obj: Switch, context: ?AbilityContext): Unit {
        for (child in obj.getChildren()) {
            if (let Some(conditional) <- (child as SvgConditional)) {
                // @ts-ignore
                let condObj: SvgConditional = conditional
                if (condObj.getRequiredExtensions() != "") {
                    continue
                }
                render(child, context)
                break
            } else {
                continue
            }
        }
    }

    private func renderUse(obj: Use, context: ?AbilityContext): Unit {
        if (obj.width.isZero() || obj.height.isZero()) {
            return
        }
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        let ref: SvgObject = obj.document().resolveIRI(obj.href) ?? return if (let Some(v) <- obj.transform) {
            this.canvas.concat(v)
        }
        let _x: Float64 = if (!obj.x.isZero()) {
            obj.x.floatValueX(this)
        } else {
            0.0
        }
        let _y: Float64 = if (!obj.y.isZero()) {
            obj.y.floatValueY(this)
        } else {
            0.0
        }
        this.canvas.translate(_x, _y, Paint(Option<Paint>.None))
        checkForClipPath(obj)
        let compositing: Bool = pushLayer()
        parentPush(obj)
        if (let Some(svg) <- (ref as Svg)) {
            let svgElem = svg
            let viewPort: Box = makeViewPort(SVGLength(), SVGLength(), obj.width, obj.height)
            statePush()
            renderSvg(svgElem, Option<Box>.None, context, viewPort: viewPort)
            statePop()
        } else if (let Some(symbol) <- (ref as Symbol)) {
            let _w: SVGLength = if (!obj.width.isZero()) {
                obj.width
            } else {
                SVGLength(100.0, u: Units.percent)
            }
            let _h: SVGLength = if (!obj.height.isZero()) {
                obj.height
            } else {
                SVGLength(100.0, u: Units.percent)
            }
            let viewPort: Box = makeViewPort(SVGLength(), SVGLength(), _w, _h)
            statePush()
            renderSymbol(symbol, viewPort, context)
            statePop()
        } else {
            render(ref, context)
        }
        parentPop()
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderSymbol(obj: Symbol, viewPort: Box, context: ?AbilityContext): Unit {
        if (viewPort.width == 0.0 || viewPort.height == 0.0) {
            return
        }
        let positioning: PreserveAspectRatio = if (let Some(v) <- obj.preserveAspectRatio) {
            v
        } else {
            PreserveAspectRatio.LETTERBOX
        }
        updateStyleForElement(this.state, obj)
        this.state.viewPort = viewPort
        if (!this.state.style.overflow) {
            setClipRect(this.state.viewPort.minX, this.state.viewPort.minY, this.state.viewPort.width,
                this.state.viewPort.height)
        }
        if (obj.viewBox != Box(0.0, 0.0, 0.0, 0.0)) {
            this.canvas.concat(calculateViewBoxTransform(this.state.viewPort, obj.viewBox, positioning))
            this.state.viewBox = obj.viewBox
        } else {
            this.canvas.translate(this.state.viewPort.minX, this.state.viewPort.minY, Paint(Option<Paint>.None))
        }
        let compositing: Bool = pushLayer()
        renderChildren(obj, true, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func renderSvg(obj: Svg, viewBox: ?Box, context: ?AbilityContext,
        viewPort!: Box = makeViewPort(obj.x, obj.y, obj.width, obj.height),
        p!: ?PreserveAspectRatio = obj.preserveAspectRatio): Unit {
        AppLog.info("Svg render")
        var positioning: ?PreserveAspectRatio = p
        if (viewPort.width == 0.0 || viewPort.height == 0.0) {
            return
        }
        if (positioning.isNone()) {
            positioning = PreserveAspectRatio.LETTERBOX
        }
        updateStyleForElement(this.state, obj)
        if (!display()) {
            return
        }
        this.state.viewPort = viewPort
        if (!this.state.style.overflow) {
            setClipRect(this.state.viewPort.minX, this.state.viewPort.minY, this.state.viewPort.width,
                this.state.viewPort.height)
        }
        checkForClipPath(obj, boundingBox: this.state.viewPort)
        if (viewBox.isSome()) {
            this.canvas.concat(calculateViewBoxTransform(this.state.viewPort, viewBox(), positioning()))
            this.state.viewBox = obj.viewBox
        } else {
            this.canvas.translate(this.state.viewPort.minX, this.state.viewPort.minY, Paint(Option<Paint>.None))
        }
        let compositing: Bool = pushLayer()
        viewportFill()
        renderChildren(obj, true, context)
        if (compositing) {
            popLayer(obj, context)
        }
    }

    private func makeViewPort(x: SVGLength, y: SVGLength, width: SVGLength, height: SVGLength): Box {
        let _x: Float64 = if (!x.isZero()) {
            x.floatValueX(this)
        } else {
            0.0
        }
        let _y: Float64 = if (!y.isZero()) {
            y.floatValueY(this)
        } else {
            0.0
        }
        let viewPortUser: Box = getCurrentViewPortInUserUnits()
        let _w: Float64 = if (!width.isZero()) {
            width.floatValueX(this)
        } else {
            viewPortUser.width
        }
        let _h: Float64 = if (!height.isZero()) {
            height.floatValueX(this)
        } else {
            viewPortUser.height
        }
        return Box(_x, _y, _w, _h)
    }

    private func objectToPath(obj: SvgElement, allowUse: Bool): Path2D {
        this.stateStack.addLast(this.state)
        this.state = RendererState(this.state)
        updateStyleForElement(this.state, obj)
        if (!display() || !visible()) {
            this.state = this.stateStack.removeLast() ?? RendererState(Option<RendererState>.None)
            return Path2D()
        }
        var path: Path2D = Path2D()
        if (let Some(use) <- (obj as Use)) {
            if (!allowUse) {
            }
            let useElement: Use = use
            let ref: ?SvgObject = obj.document().resolveIRI(useElement.href)
            if (ref.isNone()) {
                this.state = this.stateStack.removeLast() ?? RendererState(Option<RendererState>.None)
                return Path2D()
            }
            if (!(ref() is SvgElement)) {
                this.state = this.stateStack.removeLast() ?? RendererState(Option<RendererState>.None)
                return Path2D()
            }
            path = objectToPath((ref() as SvgElement)(), false)
        } else if (let Some(path2) <- (obj as Path2)) {
            path = Path2D(path2.d().d)
        } else if (let Some(rect2) <- (obj as Rect2)) {
            path = makePathAndBoundingBoxRect(rect2)
        } else if (let Some(circle2) <- (obj as Circle2)) {
            path = makePathAndBoundingBoxCircle(circle2)
        } else if (let Some(ellipse2) <- (obj as Ellipse2)) {
            path = makePathAndBoundingBoxEllipse(ellipse2)
        } else if (let Some(line) <- (obj as PolyLine)) {
            path = makePathAndBoundingBoxPolyLine(line)
        } else if (let Some(t) <- (obj as Text2)) {
            path = makePathAndBoundingBoxText(t)
        } else {
            return Path2D()
        }
        this.state = this.stateStack.removeLast() ?? RendererState(Option<RendererState>.None)
        return path
    }

    private func makePathAndBoundingBoxText(obj: Text2): Path2D {
        let textAsPath: Path2D = Path2D()
        return textAsPath
    }

    private func makePathAndBoundingBoxRect(obj: Rect2): Path2D {
        var x: Float64 = 0.0
        var y: Float64 = 0.0
        var w: Float64 = 0.0
        var h: Float64 = 0.0
        var rx: Float64 = 0.0
        var ry: Float64 = 0.0
        if (obj.rx.isZero() && obj.ry.isZero()) {
            rx = 0.0
            ry = 0.0
        } else if (obj.rx.isZero()) {
            ry = obj.ry.floatValueY(this)
            rx = ry
        } else if (obj.ry.isZero()) {
            ry = obj.rx.floatValueX(this)
            rx = ry
        } else {
            rx = obj.rx.floatValueX(this)
            ry = obj.ry.floatValueY(this)
        }
        rx = min(rx, obj.width.floatValueX(this) / 2.0)
        ry = min(ry, obj.height.floatValueY(this) / 2.0)
        x = if (!obj.x.isZero()) {
            obj.x.floatValueX(this)
        } else {
            0.0
        }
        y = if (!obj.y.isZero()) {
            obj.y.floatValueY(this)
        } else {
            0.0
        }
        w = obj.width.floatValueX(this)
        h = obj.height.floatValueY(this)
        if (obj.boundingBox == Box(0.0, 0.0, 0.0, 0.0)) {
            obj.boundingBox = Box(x, y, w, h)
        }
        let right = x + w
        let bottom = y + h
        let p: Path2D = Path2D()
        if (rx == 0.0 || ry == 0.0) {
            p.moveTo(x, y)
            p.lineTo(right, y)
            p.lineTo(right, bottom)
            p.lineTo(x, bottom)
            p.lineTo(x, y)
        } else {
            let cpx = rx * SVGRenderer.BEZIER_ARC_FACTOR
            let cpy = ry * SVGRenderer.BEZIER_ARC_FACTOR
            p.moveTo(x, y + ry)
            p.bezierCurveTo(x, y + ry - cpy, x + rx - cpx, y, x + rx, y)
            p.lineTo(right - rx, y)
            p.bezierCurveTo(right - rx + cpx, y, right, y + ry - cpy, right, y + ry)
            p.lineTo(right, bottom - ry)
            p.bezierCurveTo(right, bottom - ry + cpy, right - rx + cpx, bottom, right - rx, bottom)
            p.lineTo(x + rx, bottom)
            p.bezierCurveTo(x + rx - cpx, bottom, x, bottom - ry + cpy, x, bottom - ry)
            p.lineTo(x, y + ry)
        }
        p.closePath()
        return p
    }

    private func makePathAndBoundingBoxCircle(obj: Circle2): Path2D {
        let cx = if (!obj.cx.isZero()) {
            obj.cx.floatValueX(this)
        } else {
            0.0
        }
        let cy = if (!obj.cy.isZero()) {
            obj.cy.floatValueY(this)
        } else {
            0.0
        }
        let r = obj.r.floatValue(this)
        let left = cx - r
        let top = cy - r
        let right = cx + r
        let bottom = cy + r
        if (obj.boundingBox == Box(0.0, 0.0, 0.0, 0.0)) {
            obj.boundingBox = Box(left, top, r * 2.0, r * 2.0)
        }
        let cp = r * SVGRenderer.BEZIER_ARC_FACTOR
        let p: Path2D = Path2D()
        p.moveTo(cx, top)
        p.bezierCurveTo(cx + cp, top, right, cy - cp, right, cy)
        p.bezierCurveTo(right, cy + cp, cx + cp, bottom, cx, bottom)
        p.bezierCurveTo(cx - cp, bottom, left, cy + cp, left, cy)
        p.bezierCurveTo(left, cy - cp, cx - cp, top, cx, top)
        p.closePath()
        return p
    }

    private func makePathAndBoundingBoxEllipse(obj: Ellipse2): Path2D {
        let cx = if (!obj.cx.isZero()) {
            obj.cx.floatValueX(this)
        } else {
            0.0
        }
        let cy = if (!obj.cy.isZero()) {
            obj.cy.floatValueY(this)
        } else {
            0.0
        }
        let rx = obj.rx.floatValueX(this)
        let ry = obj.ry.floatValueY(this)
        let left = cx - rx
        let top = cy - ry
        let right = cx + rx
        let bottom = cy + ry
        if (obj.boundingBox == Box(0.0, 0.0, 0.0, 0.0)) {
            obj.boundingBox = Box(left, top, rx * 2.0, ry * 2.0)
        }
        let cpx = rx * SVGRenderer.BEZIER_ARC_FACTOR
        let cpy = ry * SVGRenderer.BEZIER_ARC_FACTOR
        let p: Path2D = Path2D()
        p.moveTo(cx, top)
        p.bezierCurveTo(cx + cpx, top, right, cy - cpy, right, cy)
        p.bezierCurveTo(right, cy + cpy, cx + cpx, bottom, cx, bottom)
        p.bezierCurveTo(cx - cpx, bottom, left, cy + cpy, left, cy)
        p.bezierCurveTo(left, cy - cpy, cx - cpx, top, cx, top)
        p.closePath()
        return p
    }

    private func makePathAndBoundingBoxPolyLine(obj: PolyLine): Path2D {
        var numPoints: Int64 = obj.points.size
        if (numPoints % 2 != 0) {
            return Path2D()
        }
        var pathCommand: String = ""
        if (numPoints > 0) {
            var i = 0
            while (numPoints >= 2) {
                if (i == 0) {
                    pathCommand += "M" + "${obj.points[i]}" + "," + "${obj.points[i + 1]}"
                } else {
                    pathCommand += "L" + "${obj.points[i]}" + "," + "${obj.points[i + 1]}"
                }
                i += 2
                numPoints -= 2
            }
            if (obj is Polygon2) {
                pathCommand += "Z"
            }
        }
        return Path2D(pathCommand)
    }

    private func realignMarkerMid(lastPos: MarkerVector, thisPos: MarkerVector, nextPos: MarkerVector): MarkerVector {
        var dot: Float64 = dotProduct(thisPos.dx, thisPos.dy, (thisPos.x - lastPos.x), (thisPos.y - lastPos.y))
        if (dot == 0.0) {
            dot = dotProduct(thisPos.dx, thisPos.dy, (nextPos.x - thisPos.x), (nextPos.y - thisPos.y))
        }
        if (dot > 0.0) {
            return thisPos
        }
        if (dot == 0.0) {
            if (thisPos.dx > 0.0 || thisPos.dy >= 0.0) {
                return thisPos
            }
        }
        thisPos.dx = -thisPos.dx
        thisPos.dy = -thisPos.dy
        return thisPos
    }

    private func dotProduct(x1: Float64, y1: Float64, x2: Float64, y2: Float64): Float64 {
        return x1 * x2 + y1 * y2
    }

    private static func atan2(y: Float64, x: Float64): Float64 {
        if (x > 0.0) {
            return atan(y / x)
        } else if (x < 0.0 && y >= 0.0) {
            return atan(y / x) + Float64.PI
        } else if (x < 0.0 && y < 0.0) {
            return atan(y / x) - Float64.PI
        } else if (x == 0.0 && y > 0.0) {
            return Float64.PI / 2.0
        } else if (x == 0.0 && y < 0.0) {
            return -Float64.PI / 2.0
        } else {
            return 0.0
        }
    }

    private func renderMarker(marker: Marker, pos: MarkerVector, context: ?AbilityContext): Unit {
        var angle: Float64 = 0.0
        var unitsScale: Float64
        statePush()
        if (marker.orient != 0.0) {
            if (marker.orient.isNaN()) {
                if (pos.dx != 0.0 || pos.dy != 0.0) {
                    angle = atan2(pos.dy, pos.dx) * 180.0 / Float64.PI
                }
            } else {
                angle = marker.orient
            }
        }
        unitsScale = if (marker.markerUnitsAreUser) {
            1.0
        } else {
            this.state.style.strokeWidth.floatValueWithDpi(this.dpi)
        }
        this.state = findInheritFromAncestorState(marker)
        let m: Matrix2D2 = Matrix2D2()
        m.translate(pos.x, y: pos.y)
        m.rotate(angle)
        m.scale(unitsScale, y: unitsScale)
        let _refX = if (!(marker.refX.isZero())) {
            marker.refX.floatValueX(this)
        } else {
            0.0
        }
        let _refY = if (!(marker.refY.isZero())) {
            marker.refY.floatValueY(this)
        } else {
            0.0
        }
        let _markerWidth = if (!(marker.markerWidth.isZero())) {
            marker.markerWidth.floatValueX(this)
        } else {
            3.0
        }
        let _markerHeight = if (!(marker.markerHeight.isZero())) {
            marker.markerHeight.floatValueY(this)
        } else {
            3.0
        }
        if (marker.viewBox != Box(0.0, 0.0, 0.0, 0.0)) {
            var xScale: Float64 = _markerWidth / marker.viewBox.width
            var yScale: Float64 = _markerHeight / marker.viewBox.height
            let positioning: PreserveAspectRatio = if (let Some(v) <- marker.preserveAspectRatio) {
                v
            } else {
                PreserveAspectRatio.LETTERBOX
            }
            if (positioning != PreserveAspectRatio.STRETCH) {
                let aspectScale: Float64 = if (positioning.getScale() == Scale.slice) {
                    max(xScale, yScale)
                } else {
                    min(xScale, yScale)
                }
                xScale = aspectScale
                yScale = aspectScale
            }
            m.translate(-_refX * xScale, y: -_refY * yScale)
            this.canvas.concat(m)
            let imageW = marker.viewBox.width * xScale
            let imageH = marker.viewBox.height * yScale
            var xOffset: Float64 = 0.0
            var yOffset: Float64 = 0.0
            if (positioning.getAlignment() != "") {
                if (positioning.getAlignment() == Alignment.xMidYMin) {
                } else if (positioning.getAlignment() == Alignment.xMidYMid) {}
                else if (positioning.getAlignment() == Alignment.xMidYMax) {
                    xOffset -= (_markerWidth - imageW) / 2.0
                } else if (positioning.getAlignment() == Alignment.xMaxYMin) {}
                else if (positioning.getAlignment() == Alignment.xMaxYMid) {}
                else if (positioning.getAlignment() == Alignment.xMaxYMax) {
                    xOffset -= (_markerWidth - imageW)
                } else {}
            }

            if (positioning.getAlignment() != "") {
                if (positioning.getAlignment() == Alignment.xMinYMid) {
                } else if (positioning.getAlignment() == Alignment.xMidYMid) {}
                else if (positioning.getAlignment() == Alignment.xMaxYMid) {
                    yOffset -= (_markerHeight - imageH) / 2.0
                } else if (positioning.getAlignment() == Alignment.xMinYMax) {}
                else if (positioning.getAlignment() == Alignment.xMidYMax) {}
                else if (positioning.getAlignment() == Alignment.xMaxYMax) {
                    yOffset -= (_markerHeight - imageH)
                } else {}
            }

            if (!this.state.style.overflow) {
                setClipRect(xOffset, yOffset, _markerWidth, _markerHeight)
            }
            m.setValues()
            m.scale(xScale, y: yScale)
            this.canvas.concat(m)
        } else {
            m.translate(-_refX, y: -_refY)
            this.canvas.concat(m)
            if (!this.state.style.overflow) {
                this.setClipRect(0.0, 0.0, _markerWidth, _markerHeight)
            }
        }
        let compositing: Bool = pushLayer()
        renderChildren(marker, false, context)
        if (compositing) {
            popLayer(marker, context)
        }
        statePop()
    }
}

public class RendererState {
    var style: Style
    var hasFill: Bool = true
    var hasStroke: Bool = false
    var viewPort: Box = Box(0.0, 0.0, 0.0, 0.0)
    var viewBox: Box = Box(0.0, 0.0, 0.0, 0.0)
    var fillPaint: Paint
    var spacePreserve: Bool = false
    var strokePaint: Paint

    init(copy: ?RendererState) {
        if (let Some(v) <- copy) {
            this.hasFill = v.hasFill
            this.hasStroke = v.hasStroke
            this.fillPaint = Paint(v.fillPaint)
            this.strokePaint = Paint(v.strokePaint)
            if (v.viewPort != Box(0.0, 0.0, 0.0, 0.0)) {
                this.viewPort = Box(v.viewPort.minX, v.viewPort.minY, v.viewPort.width, v.viewPort.height)
            }
            if (v.viewBox != Box(0.0, 0.0, 0.0, 0.0)) {
                this.viewBox = Box(v.viewBox.minX, v.viewBox.minY, v.viewBox.width, v.viewBox.height)
            }
            this.spacePreserve = v.spacePreserve
            this.style = v.style
        } else {
            this.fillPaint = Paint(Option<Paint>.None)
            this.fillPaint.setStroke(false)
            this.strokePaint = Paint(Option<Paint>.None)
            this.strokePaint.setStroke(true)
            this.style = Style.getDefaultStyle()
        }
    }
}

abstract class TextProcessor {
    public func doTextContainer(obj: TextContainer): Bool {
        return true
    }

    public func processText(text: String, state: RendererState, canvas: CanvasImpl): Unit
}

class PlainTextDrawer <: TextProcessor {
    private var x: Float64 = 0.0
    private var y: Float64 = 0.0
    private var dx: Float64 = 0.0
    private var dy: Float64 = 0.0
    private var textAnchor: String = ""

    init(x: Float64, y: Float64, dx: Float64, dy: Float64, textAnchor: String) {
        super()
        this.x = x
        this.y = y
        this.dx = dx
        this.dy = dy
        this.textAnchor = textAnchor
    }

    public func processText(text: String, state: RendererState, canvas: CanvasImpl): Unit {
        if (!textAnchor.isEmpty()) {
            let textWidth: Float64 = canvas.getContext().measureText(text).width
            if (textAnchor == "middle") {
                x -= (textWidth / 2.0)
            } else if (textAnchor == "end") {
                x -= textWidth
            }
        }
        if (visible(state)) {
            // Android/Skia divides letterspacing and puts half before and after each letter.
            // We need to readjust initial text X position to counter that.
            let letterspacingAdj: Float64 = 2.5
            let opt: Float64 = if ((x + dx) > letterspacingAdj) {
                x + dx - letterspacingAdj
            } else {
                x + dx
            }
            if (state.hasFill) {
                canvas.drawText(text, opt, y + dy, state.fillPaint)
            }
            if (state.hasStroke) {
                canvas.drawText(text, opt, y + dy, state.strokePaint)
            }
        }
        x += canvas.getContext().measureText(text).width
    }

    private func visible(state: RendererState): Bool {
        return state.style.visibility
    }
}

class MarkerVector {
    var x: Float64 = 0.0
    var y: Float64 = 0.0
    var dx: Float64 = 0.0
    var dy: Float64 = 0.0
    var isAmbiguous: Bool = false

    init() {}

    init(x: Float64, y: Float64, dx: Float64, dy: Float64) {
        this.x = x
        this.y = y
        let len = sqrt(dx * dx + dy * dy)
        if (len != 0.0) {
            this.dx = (dx / len)
            this.dy = (dy / len)
        }
    }

    func add(x: Float64, y: Float64): Unit {
        var dx = (x - this.x)
        var dy = (y - this.y)
        let len = sqrt(dx * dx + dy * dy)
        if (len != 0.0) {
            dx = (dx / len)
            dy = (dy / len)
        }
        if (dx == -this.dx && dy == -this.dy) {
            this.isAmbiguous = true
            this.dx = -dy
            this.dy = dx
        } else {
            this.dx += dx
            this.dy += dy
        }
    }

    func addMarkerVector(v2: MarkerVector): Unit {
        if (v2.dx == -this.dx && v2.dy == -this.dy) {
            this.isAmbiguous = true
            this.dx = -v2.dy
            this.dy = v2.dx
        } else {
            this.dx += v2.dx
            this.dy += v2.dy
        }
    }

    public operator func ==(that: MarkerVector): Bool {
        return this.x == that.x && this.y == that.y && this.dx == that.dx && this.dy == that.dy && this.isAmbiguous ==
            that.isAmbiguous
    }

    public operator func !=(that: MarkerVector): Bool {
        return !(this == that)
    }
}

class MarkerPositionCalculator <: PathInterface {
    private let markers: ArrayList<MarkerVector> = ArrayList<MarkerVector>()
    private var startX: Float64 = 0.0
    private var startY: Float64 = 0.0
    private var lastPos: MarkerVector = MarkerVector()
    private var startArc: Bool = false
    private var normalCubic: Bool = true
    private var subpathStartIndex: Int64 = -1
    private var closepathReAdjustPending: Bool = false

    init(pathDef: ?PathDefinition) {
        if (let Some(pathDef) <- pathDef) {
            pathDef.enumeratePath(this)
            if (this.closepathReAdjustPending) {
                this.lastPos.addMarkerVector(this.markers[this.subpathStartIndex])
                this.markers.remove(at: this.subpathStartIndex)
                this.markers.add(lastPos, at: this.subpathStartIndex)
                this.closepathReAdjustPending = false
            }
            if (this.lastPos != MarkerVector()) {
                this.markers.add(this.lastPos)
            }
        } else {
            return
        }
    }

    func getMarkers(): ArrayList<MarkerVector> {
        return this.markers
    }

    public func moveTo(x: Float64, y: Float64): Unit {
        if (this.closepathReAdjustPending) {
            this.lastPos.addMarkerVector(this.markers[this.subpathStartIndex])
            this.markers.remove(at: this.subpathStartIndex)
            this.markers.add(this.lastPos, at: this.subpathStartIndex)
            this.closepathReAdjustPending = false
        }
        if (this.lastPos != MarkerVector()) {
            this.markers.add(this.lastPos)
        }
        this.startX = x
        this.startY = y
        this.lastPos = MarkerVector(x, y, 0.0, 0.0)
        this.subpathStartIndex = this.markers.size
    }

    public func lineTo(x: Float64, y: Float64): Unit {
        this.lastPos.add(x, y)
        this.markers.add(this.lastPos)
        this.lastPos = MarkerVector(x, y, x - this.lastPos.x, y - this.lastPos.y)
        this.closepathReAdjustPending = false
    }

    public func cubicTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64, x3: Float64, y3: Float64): Unit {
        if (this.normalCubic || this.startArc) {
            this.lastPos.add(x1, y1)
            this.markers.add(this.lastPos)
            this.startArc = false
        }
        this.lastPos = MarkerVector(x3, y3, x3 - x2, y3 - y2)
        this.closepathReAdjustPending = false
    }

    public func quadTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64): Unit {
        this.lastPos.add(x1, y1)
        this.markers.add(this.lastPos)
        this.lastPos = MarkerVector(x2, y2, x2 - x1, y2 - y1)
        this.closepathReAdjustPending = false
    }

    public func arcTo(rx: Float64, ry: Float64, xAxisRotation: Float64, largeArcFlag: Bool, sweepFlag: Bool, x: Float64,
        y: Float64): Unit {
        this.startArc = true
        this.normalCubic = false
        SVGRenderer.arcTo(this.lastPos.x, this.lastPos.y, rx, ry, xAxisRotation, largeArcFlag, sweepFlag, x, y, this)
        this.normalCubic = true
        this.closepathReAdjustPending = false
    }

    public func close(): Unit {
        this.markers.add(this.lastPos)
        lineTo(this.startX, this.startY)
        this.closepathReAdjustPending = true
    }
}
