/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

class SVGRenderer {
    private static let PATTERN_TABS_OR_LINE_BREAKS: Regex = Regex("[\\n\\t]")
    private static let PATTERN_TABS: Regex = Regex("\\t")
    private static let PATTERN_LINE_BREAKS: Regex = Regex("\\n")
    private static let PATTERN_START_SPACES: Regex = Regex("^\\s+")
    private static let PATTERN_END_SPACES: Regex = Regex("\\s+$")
    private static let PATTERN_DOUBLE_SPACES: Regex = Regex("\\s{2,}")
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
        this.stateStack.append(RendererState(this.state))
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
            if (let Some(fill) <- style.fill as Colour) {
                state.hasFill = fill != Colour.TRANSPARENT
            }
        }

        if (isSpecified(style, Style.SPECIFIED_FILL_OPACITY)) {
            state.style.fillOpacity = style.fillOpacity
        } else {
            state.style.fillOpacity = 1.0
        }

        if (isSpecified(style, Style.SPECIFIED_FILL | Style.SPECIFIED_FILL_OPACITY | Style.SPECIFIED_COLOR | Style.SPECIFIED_OPACITY)) {
            if (let Some(v) <- state.style.fill) {
                setPaintColour(state, true, v)
            }
        }

        if (isSpecified(style, Style.SPECIFIED_FILL_RULE)) {
            state.style.fillRule = style.fillRule
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE)) {
            state.style.stroke = style.stroke
            if (let Some(stroke) <- style.stroke() as Colour) {
                state.hasStroke = stroke != Colour.TRANSPARENT
            }
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE_OPACITY)) {
            state.style.strokeOpacity = style.strokeOpacity
        }

        if (isSpecified(style, Style.SPECIFIED_STROKE | Style.SPECIFIED_STROKE_OPACITY | Style.SPECIFIED_COLOR | Style.SPECIFIED_OPACITY)) {
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
                    intervals.insert(i, state.style.strokeDashArray[i % n].floatValue(this))
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
            state.fillPaint.setFontSize(Length(style.fontSize.floatValue(this, max: currentFontSize)))
            state.strokePaint.setFontSize(Length(style.fontSize.floatValue(this, max: currentFontSize)))
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
        if (let Some(paint) <- paint as Colour) {
            col = paint.colour
        } else if (let Some(v) <- paint as CurrentColor) {
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
        return this.state.fillPaint.getFontSize().value
    }

    func getCurrentFontXHeight(): Float64 {
        let value: Length = this.state.fillPaint.getFontSize()
        return this.state.fillPaint.getFontSize().value / 2.0
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

    func renderDocument(document: SVGBase, renderOptions: RenderOptionsBase, context: ?AbilityContext): Unit {
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
                if (let Some(view) <- v as View) {
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
                let parser: CSSParser = CSSParser(source: Source.RenderOptions, externalFileResolver: this.externalFileResolver)
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
            viewPort = Box(rootObj.viewBox.minX, rootObj.viewBox.minY, rootObj.viewBox.width, rootObj.viewBox.height)
        }
        if (!rootObj.width.isZero()) {
            viewPort.width = rootObj.width.floatValueBox(this)
        }

        if (!rootObj.height.isZero()) {
            viewPort.height = rootObj.height.floatValueBox(this)
        }
        renderSvg4(rootObj, viewPort, viewBox, preserveAspectRatio(), context)
        statePop()
        if (renderOptions.hasCss()) {
            document.clearRenderCSSRules()
        }
    }

    private func checkXMLSpaceAttribute(obj: SvgObject): Unit {
        if (let Some(v) <- obj as SvgElementBase) {
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
        this.stateStack.append(this.state)
        this.state = RendererState(this.state)
    }

    private func statePop(): Unit {
        this.combinedPath = Path2D()
        this.canvas.restore()
        this.state = this.stateStack.popLast() ?? RendererState()
    }

    private func renderSvg4(obj: Svg, viewPort: Box, viewBox: Box, p: PreserveAspectRatio, context: ?AbilityContext): Unit {
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
            this.canvas.concat(calculateViewBoxTransform(this.state.viewPort, viewBox, positioning))
            this.state.viewBox = obj.viewBox
        } else {
            this.canvas.translate(this.state.viewPort.minX, this.state.viewPort.minY, Paint())
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
        let ref: ?SvgObject = obj.document().resolveIRI(this.state.style.clipPath)
        if (ref.isNone()) {
            return None
        }
        let clipPath: ClipPath = (ref() as ClipPath)()
        this.stateStack.append(this.state)
        this.state = findInheritFromAncestorState(clipPath)
        let userUnits: Bool = (clipPath.clipPathUnitsAreUser == false || clipPath.clipPathUnitsAreUser)
        let m: Matrix2D2 = Matrix2D2()
        if (!userUnits) {
            m.translate(boundingBox.minX, y: boundingBox.minY)
            m.scale(boundingBox.width, boundingBox.height)
        }
        if (let Some(v) <- clipPath.transform) {
            m.append(v.a, v.b, v.c, v.d, v.tx, v.ty)
        }
        var combinedPath: Path2D = Path2D()
        for (i in 0..clipPath.children.size) {
            let child = clipPath.children[i]
            if (let Some(ele) <- child as SvgElement) {
//                combinedPath = objectToPath(ele, true) TODO..
            } else {
                continue
            }
        }
        if (!this.state.style.clipPath.isEmpty()) {
            let clipClipPath: ?Path2D = calculateClipPath(clipPath, clipPath.boundingBox)
            if (let Some(v) <- clipClipPath) {
                combinedPath.addPath(v)
            }
        }
        this.canvas.getContext().transform(m.a, m.b, m.c, m.d, m.getE(), m.getF())
        this.state = this.stateStack.popLast() ?? RendererState()
        return combinedPath
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
            m.scale(xScale, yScale)
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
        m.scale(scale, scale)
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
        this.stateStack.append(this.state)
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
        if (let Some(colo) <- this.state.style.viewportFill as Colour) {
            col = colo.colour
        } else if (let Some(current) <- this.state.style.viewportFill as CurrentColor) {
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
        this.parentStack.append(obj)
        this.matrixStack.append(this.canvas.getMatrix())
    }

    private func parentPop(): Unit {
        this.parentStack.popLast()
        this.matrixStack.popLast()
    }

    private func render(obj: SvgObject, context: ?AbilityContext): Unit {
        // TODO..
    }

    private func popLayer(obj: SvgElement, context: ?AbilityContext, originalObjBBox!: Box = obj.boundingBox): Unit {
        if (this.state.style.mask != "") {
            this.canvas.getContext().globalCompositeOperation(CompositeOperation.DestinationIn)
            let ref: ?SvgObject = this.document().resolveIRI(this.state.style.mask)
            if (let Some(v) <- ref) {
                if (let Some(ref) <- v as Mask) {
                    renderMask(ref, obj, context, originalObjBBox: originalObjBBox)
                }
            }
            // The retore composites the luminanceToAlpha layer with the masks alpha
            this.canvas.restore()

            // Apply the final mask to the original object waiting in the open layer created in pushLayer()
            this.canvas.restore()
        }
        statePop()
    }

    private func renderMask(mask: Mask, obj: SvgElement, context: ?AbilityContext, originalObjBBox!: Box = Box(0.0, 0.0, 200.0, 200.0)): Unit {
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
        let maskContentUnitsAreUser: Bool = mask.maskContentUnitsAreUser
        if (!maskContentUnitsAreUser) {
            this.canvas.translate(originalObjBBox.minX, originalObjBBox.minY, Paint())
            this.canvas.scale(originalObjBBox.width, originalObjBBox.height, Paint())
        }
        renderChildren(mask, false, context)
        this.canvas.restore()
        if (compositing) {
            popLayer(obj, context, originalObjBBox: originalObjBBox)
        }
        statePop()
    }

    private func findInheritFromAncestorState(o: SvgObject, n!: RendererState = RendererState()): RendererState {
        var obj: SvgObject = o
        var newState: RendererState = n
        updateStyle(newState, Style.getDefaultStyle())
        let ancestors: ArrayList<SvgElementBase> = ArrayList<SvgElementBase>()
        while (true) {
            if (let Some(ele) <- obj as SvgElementBase) {
                ancestors.insert(0, ele)
            }
            if (let Some(v) <- obj.parent as SvgObject) {
                obj = v
            } else {
                break
            }
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
        if (let Some(fill) <- this.state.style.fill as PaintReference) {
            decodePaintReference(true, obj.boundingBox, fill)
        }
        if (let Some(stroke) <- this.state.style.stroke as PaintReference) {
            decodePaintReference(false, obj.boundingBox, stroke)
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
        if (let Some(svgLinearGradient) <- ref() as SvgLinearGradient) {
            makeLinearGradient(isFill, boundingBox, svgLinearGradient)
        } else if (let Some(svgRadialGradient) <- ref() as SvgRadialGradient) {
            makeRadialGradient(isFill, boundingBox, svgRadialGradient)
        } else if (let Some(solidColor) <- ref() as SolidColor) {
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
            m.scale(boundingBox.width, boundingBox.height)
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
                positions[i] = offset
                lastOffset = offset
            } else {
                positions[i] = lastOffset
            }
            statePush()
            updateStyleForElement(this.state, stop)
            var col: Colour = if (let Some(stopColor) <- this.state.style.stopColor as Colour) {
                stopColor
            } else {
                Colour.BLACK
            }
            colours.insert(i, col.colour)
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
            m.scale(boundingBox.width, boundingBox.height)
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
                positions[i] = offset
                lastOffset = offset
            } else {
                positions[i] = lastOffset
            }
            statePush()
            updateStyleForElement(this.state, stop)
            var col = this.state.style.stopColor as Colour
            if (col.isNone()) {
                col = Colour.BLACK
            }
            colours.insert(i, col().colour)
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
        // TODO..
    }

    private func doFilledPath(obj: SvgElement, path: Path2D, context: ?AbilityContext): Unit {
        if (let Some(fill) <- this.state.style.fill as PaintReference) {
            let ref: ?SvgObject = this.document().resolveIRI(fill.href)
            if (let Some(v) <- ref) {
                if (let Some(ref) <- v as Pattern) {
                    let pattern: Pattern = ref
                    fillWithPattern(obj, path, pattern, context)
                    return
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
        let baseState: RendererState = RendererState()
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
                    this.canvas.translate(stepX, stepY, Paint())
                    if (!patternContentUnitsAreUser) {
                        this.canvas.scale(obj.boundingBox.width, obj.boundingBox.height, Paint())
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

}

class RendererState {
    var style: Style = Style()
    var hasFill: Bool = true
    var hasStroke: Bool = false
    var viewPort: Box = Box(0.0, 0.0, 0.0, 0.0)
    var viewBox: Box = Box(0.0, 0.0, 0.0, 0.0)
    var fillPaint: Paint = Paint()
    var spacePreserve: Bool = false
    var strokePaint: Paint = Paint()

    init() {
        this.fillPaint = Paint()
        this.fillPaint.setStroke(false)
        this.strokePaint = Paint()
        this.strokePaint.setStroke(true)
        this.style = Style.getDefaultStyle()
    }

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
            this.fillPaint = Paint()
            this.fillPaint.setStroke(false)
            this.strokePaint = Paint()
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

    init(x: Float64, y: Float64) {
        super()
        this.x = x
        this.y = y
    }

    public func processText(text: String, state: RendererState, canvas: CanvasImpl): Unit {
        if (visible(state)) {
            // Android/Skia divides letterspacing and puts half before and after each letter.
            // We need to readjust initial text X position to counter that.
            let letterspacingAdj = 0.0
            if (state.hasFill) {
                canvas.drawText(text, this.x - letterspacingAdj, this.y, state.fillPaint)
            }
            if (state.hasStroke) {
                canvas.drawText(text, this.x - letterspacingAdj, this.y, state.strokePaint)
            }
        }
        // Update the current text position
        this.x += canvas.getContext().measureText(text).width
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
                this.markers.remove(this.subpathStartIndex)
                this.markers.insert(this.subpathStartIndex, lastPos)
                this.closepathReAdjustPending = false
            }
            if (this.lastPos != MarkerVector()) {
                this.markers.append(this.lastPos)
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
            this.markers.remove(this.subpathStartIndex)
            this.markers.insert(this.subpathStartIndex, this.lastPos)
            this.closepathReAdjustPending = false
        }
        if (this.lastPos != MarkerVector()) {
            this.markers.append(this.lastPos)
        }
        this.startX = x
        this.startY = y
        this.lastPos = MarkerVector(x, y, 0.0, 0.0)
        this.subpathStartIndex = this.markers.size
    }

    public func lineTo(x: Float64, y: Float64): Unit {
        this.lastPos.add(x, y)
        this.markers.append(this.lastPos)
        this.lastPos = MarkerVector(x, y, x - this.lastPos.x, y - this.lastPos.y)
        this.closepathReAdjustPending = false
    }

    public func cubicTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64, x3: Float64, y3: Float64): Unit {
        if (this.normalCubic || this.startArc) {
            this.lastPos.add(x1, y1)
            this.markers.append(this.lastPos)
            this.startArc = false
        }
        this.lastPos = MarkerVector(x3, y3, x3 - x2, y3 - y2)
        this.closepathReAdjustPending = false
    }

    public func quadTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64): Unit {
        this.lastPos.add(x1, y1)
        this.markers.append(this.lastPos)
        this.lastPos = MarkerVector(x2, y2, x2 - x1, y2 - y1)
        this.closepathReAdjustPending = false
    }

    public func arcTo(rx: Float64, ry: Float64, xAxisRotation: Float64, largeArcFlag: Bool, sweepFlag: Bool, x: Float64,
        y: Float64): Unit {
        this.startArc = true
        this.normalCubic = false
//        SVGRenderer.arcTo(this.lastPos.x, this.lastPos.y, rx, ry, xAxisRotation, largeArcFlag, sweepFlag, x, y, this) TODO..
        this.normalCubic = true
        this.closepathReAdjustPending = false
    }

    public func close(): Unit {
        this.markers.append(this.lastPos)
        lineTo(this.startX, this.startY)
        this.closepathReAdjustPending = true
    }
}
