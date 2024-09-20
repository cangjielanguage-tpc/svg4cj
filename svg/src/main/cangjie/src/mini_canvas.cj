/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

import ohos.state_macro_manage.*

@Component
public class MiniCanvas {
    var settings: RenderingContextSettings = RenderingContextSettings(antialias: true)
    var context: CanvasRenderingContext2D = CanvasRenderingContext2D(this.settings)
    var miniCanvas: CanvasImpl = CanvasImpl(this.context)
    var onDraw: (canvas: ICanvas) -> Unit = {canvas => ()}
    var clickListener: (event: ClickEvent) -> Unit = {event => ()}
    var touchListener: (event: TouchEvent) -> Unit = {event => ()}

    func build() {
        Canvas(this.miniCanvas.context).width(100.percent).height(100.percent).backgroundColor(Color(0xFFFFFF)).id(
            "really_mini_canvas").onReady({
            => onDraw(this.miniCanvas)
        }).onClick({
            event => clickListener(event)
        }).onTouch({
            event => touchListener(event)
        })
    }
}

public class Paint {
    private var offScreen: Bool = false
    private var stroke: Bool = false
    private var alpha: Float64 = 1.0
    private var color: Color = Color(0x000000)
    private var strokeWidth: Float64 = 2.0
    private var fontAlign: TextAlignStyle = TextAlignStyle.Start
    private var fontBaseline: TextBaseline = TextBaseline.Top
    private var fontSize: Length = vp2px(Length(20, unitType: LengthType.vp)) ?? Length(0.0, unitType: LengthType.vp)
    private var fontStyle: FontStyle = FontStyle.Normal
    private var fontWeight: FontWeight = FontWeight.Normal
    private var fontFamily: String = "sans-serif"
    private var shadowBlur: Int64 = 0
    private var shadowColor: Color = Color(0x000000)
    private var shadowOffsetX: Int64 = 0
    private var shadowOffsetY: Int64 = 0
    private var globalCompositeOperation: String = ""
    private var lineCap: LineCapStyle = LineCapStyle.Butt
    private var lineJoin: LineJoinStyle = LineJoinStyle.Miter
    private var strokeMiterLimit: Float64 = 0.0
    private var strokeDashArray: ArrayList<Float64> = ArrayList<Float64>()
    private var strokeDashOffset: Int64 = 0
    private var gr: ?CanvasGradient = None

    init() {}

    init(paint: Paint) {
        this.offScreen = paint.offScreen
        this.stroke = paint.stroke
        this.alpha = paint.alpha
        this.color = paint.color
        this.strokeWidth = paint.strokeWidth
        this.fontAlign = paint.fontAlign
        this.fontBaseline = paint.fontBaseline
        this.fontSize = paint.fontSize
        this.fontStyle = paint.fontStyle
        this.fontWeight = paint.fontWeight
        this.fontFamily = paint.fontFamily
        this.shadowBlur = paint.shadowBlur
        this.shadowColor = paint.shadowColor
        this.shadowOffsetX = paint.shadowOffsetX
        this.shadowOffsetY = paint.shadowOffsetY
        this.globalCompositeOperation = paint.globalCompositeOperation
        this.lineCap = paint.lineCap
        this.lineJoin = paint.lineJoin
        this.strokeMiterLimit = paint.strokeMiterLimit
        this.strokeDashArray = paint.strokeDashArray
        this.strokeDashOffset = paint.strokeDashOffset
    }

    func getFontSize(): Length {
        return this.fontSize
    }

    func setGradient(gr: CanvasGradient): Unit {
        this.gr = gr
    }

    func setStrokeDashOffset(strokeDashOffset: Int64): Unit {
        this.strokeDashOffset = strokeDashOffset
    }

    func setStrokeDashArray(strokeDashArray: ArrayList<Float64>): Unit {
        this.strokeDashArray = strokeDashArray
    }

    func setStrokeMiterLimit(strokeMiterLimit: Float64): Unit {
        this.strokeMiterLimit = strokeMiterLimit
    }

    func setLineJoin(lineJoin: LineJoinStyle): Unit {
        this.lineJoin = lineJoin
    }

    func setLineCap(lineCap: LineCapStyle): Unit {
        this.lineCap = lineCap
    }

    func setOffScreen(offScreen: Bool): Paint {
        this.offScreen = offScreen
        return this
    }

    func isOffScreen(): Bool {
        return this.offScreen
    }

    func setShadowOffsetY(shadowOffsetY: Int64): Paint {
        this.shadowOffsetY = shadowOffsetY
        return this
    }

    func getShadowOffsetY(): Int64 {
        return this.shadowOffsetY
    }

    func setShadowOffsetX(shadowOffsetX: Int64): Paint {
        this.shadowOffsetX = shadowOffsetX
        return this
    }

    func getShadowOffsetX(): Int64 {
        return this.shadowOffsetX
    }

    func setShadowColor(shadowColor: Color): Paint {
        this.shadowColor = shadowColor
        return this
    }

    func getGradient(): ?CanvasGradient {
        return this.gr
    }

    func getShadowColor(): Color {
        return this.shadowColor
    }

    func setShadowBlur(shadowBlur: Int64): Paint {
        this.shadowBlur = shadowBlur
        return this
    }

    func getShadowBlur(): Int64 {
        return this.shadowBlur
    }

    func setFontStyle(fontStyle: FontStyle): Paint {
        this.fontStyle = fontStyle
        return this
    }

    func getFontStyle(): FontStyle {
        return this.fontStyle
    }

    func setFontWeight(fontWeight: FontWeight): Paint {
        this.fontWeight = fontWeight
        return this
    }

    func getFontWeight(): FontWeight {
        return this.fontWeight
    }

    func setFontFamily(fontFamily: String): Paint {
        this.fontFamily = fontFamily
        return this
    }

    func getFontFamily(): String {
        return this.fontFamily
    }

    func setStroke(stroke: Bool): Paint {
        this.stroke = stroke
        return this
    }

    func isStroke(): Bool {
        return this.stroke
    }

    func setAlpha(alpha: Float64): Paint {
        this.alpha = if (alpha < 0.0) {
            0.0
        } else {
            alpha
        }
        this.alpha = if (alpha > 1.0) {
            1.0
        } else {
            alpha
        }
        return this
    }

    func getAlpha(): Float64 {
        return this.alpha
    }

    func setColor(color: Color): Paint {
        this.color = color
        return this
    }

    func getColor(): Color {
        return this.color
    }

    func setStrokeWidth(strokeWidth: Float64): Paint {
        this.strokeWidth = if (strokeWidth < 0.0) {
            0.0
        } else {
            strokeWidth
        }
        return this
    }

    func getStrokeWidth(): Float64 {
        return this.strokeWidth
    }

    func setFontAlign(fontAlign: TextAlignStyle): Paint {
        this.fontAlign = fontAlign
        return this
    }

    func getFontAlign(): TextAlignStyle {
        return this.fontAlign
    }

    func setFontBaseline(fontBaseline: TextBaseline): Paint {
        this.fontBaseline = fontBaseline
        return this
    }

    func getFontBaseline(): TextBaseline {
        return this.fontBaseline
    }

    func setFontSize(fontSize: Length): Paint {
        this.fontSize = if (fontSize.value < 0.0) {
            Length(0.0)
        } else {
            fontSize
        }
        return this
    }

    func setGlobalCompositeOperation(globalCompositeOperation: String): Unit {
        this.globalCompositeOperation = globalCompositeOperation
    }

    func getGlobalCompositeOperation(): String {
        return this.globalCompositeOperation
    }
}

public interface ICanvas {
    func drawLine(startX: Float64, startY: Float64, stopX: Float64, stopY: Float64, paint: ?Paint): Unit

    func drawText(text: String, x: Float64, y: Float64, paint: ?Paint): Unit

    func drawCircle(x: Float64, y: Float64, radius: Float64, paint: ?Paint): Unit

    func drawOval(x: Float64, y: Float64, width: Float64, height: Float64, paint: ?Paint): Unit

    func drawArc(x: Float64, y: Float64, radius: Float64, startAngle: Float64, endAngle: Float64, paint: ?Paint,
        counterclockwise: Bool): Unit

    func drawRect(x: Float64, y: Float64, width: Float64, height: Float64, paint: ?Paint): Unit

    func drawRoundRect(x: Float64, y: Float64, width: Float64, height: Float64, radius: Float64, paint: ?Paint): Unit

    func drawImage(image: ImageBitmap, sx: Float64, sy: Float64, sWidth: Float64, sHeight: Float64, dx: Float64,
        dy: Float64, dWidth: Float64, dHeight: Float64, paint: ?Paint): Unit

    func drawImage(image: PixelMap, sx: Float64, sy: Float64, sWidth: Float64, sHeight: Float64, dx: Float64,
        dy: Float64, dWidth: Float64, dHeight: Float64, paint: ?Paint): Unit

    func measureText(text: String, pain: Paint): TextMetrics

    func rotate(x: Float64, y: Float64, angle: Float64, paint: Paint): Unit

    func scale(x: Float64, y: Float64, paint: Paint): Unit

    func translate(x: Float64, y: Float64, paint: Paint): Unit

    func restore(paint!: Paint): Unit

    func save(paint!: Paint): Unit

    //  func clear(): Unit
    func clear(width: Float64, height: Float64): Unit

    //  func getPixelMap(): PixelMap
    func getPixelMap(width: Float64, height: Float64): PixelMap
}

public class CanvasImpl <: ICanvas {
    private var matrix: Matrix2D2 = Matrix2D2()
    public var context: CanvasRenderingContext2D

    init(context: CanvasRenderingContext2D) {
        this.context = context
    }

    private func updateContextAttributes(context: CanvasRenderingContext2D, paint: Paint): Unit {
        context.lineWidth(paint.getStrokeWidth())
        context.fillStyle(paint.getColor())
        context.strokeStyle(paint.getColor())
        context.globalAlpha(paint.getAlpha())
        context.textBaseline(paint.getFontBaseline())
        context.textAlign(paint.getFontAlign())
        if (paint.getShadowBlur() > 0) {
            context.shadowBlur(paint.getShadowBlur())
            context.shadowColor(paint.getShadowColor())
            context.shadowOffsetX(paint.getShadowOffsetX())
            context.shadowOffsetY(paint.getShadowOffsetY())
        }
        context.font(style: paint.getFontStyle(), weight: paint.getFontWeight(), size: paint.getFontSize(),
            family: paint.getFontFamily())
    }

    public func drawLine(startX: Float64, startY: Float64, stopX: Float64, stopY: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawLineInternal(this.context, startX, startY, stopX, stopY, v)
        }
    }

    private func drawLineInternal(context: CanvasRenderingContext2D, startX: Float64, startY: Float64, stopX: Float64,
        stopY: Float64, paint: Paint): Unit {
        updateContextAttributes(context, paint)
        context.beginPath()
        context.moveTo(startX, startY)
        context.lineTo(stopX, stopY)
        context.stroke()
    }

    public func drawText(text: String, x: Float64, y: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawTextInternal(this.context, text, x, y, v)
        }
    }

    private func drawTextInternal(context: CanvasRenderingContext2D, text: String, x: Float64, y: Float64, paint: Paint): Unit {
        updateContextAttributes(context, paint)
        context.beginPath()
        context.font(size: paint.getFontSize(), family: "sans-serif")
        if (paint.isStroke()) {
            context.strokeText(text, x, y)
        } else {
            context.fillText(text, x, y)
        }
    }

    public func drawCircle(x: Float64, y: Float64, radius: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawCircleInternal(this.context, x, y, radius, v)
        }
    }

    private func drawCircleInternal(context: CanvasRenderingContext2D, x: Float64, y: Float64, radius: Float64,
        paint: Paint): Unit {
        updateContextAttributes(context, paint)
        context.beginPath()
        context.arc(x, y, radius, 0.0, Float64.PI * 2.0)
        invalidate(context, paint)
    }

    public func drawOval(x: Float64, y: Float64, width: Float64, height: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawOvalInternal(this.context, x, y, width, height, v)
        }
    }

    public func concat(matrix: Matrix2D2): Unit {
        this.context.transform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty)
    }

    private func drawOvalInternal(context: CanvasRenderingContext2D, x: Float64, y: Float64, width: Float64,
        height: Float64, paint: Paint): Unit {
        updateContextAttributes(context, paint)
        context.beginPath()
        context.ellipse(x + (width / 2.0), y + (height / 2.0), (width / 2.0), (height / 2.0), 0.0, 0.0, Float64.PI * 2.0
        )
        invalidate(context, paint)
    }

    public func drawArc(x: Float64, y: Float64, radius: Float64, startAngle: Float64, endAngle: Float64, paint: ?Paint,
        counterclockwise: Bool): Unit {
        if (let Some(v) <- paint) {
            drawArcInternal(this.context, x, y, radius, startAngle, endAngle, v, counterclockwise)
        }
    }

    public func drawArcInternal(context: CanvasRenderingContext2D, x: Float64, y: Float64, radius: Float64,
        startAngle: Float64, endAngle: Float64, paint: Paint, counterclockwise: Bool): Unit {
        updateContextAttributes(context, paint)
        context.beginPath()
        if (!paint.isStroke()) {
            context.moveTo(x, y)
        }
        context.arc(x, y, radius, startAngle / 360.0 * Float64.PI * 2.0, endAngle / 360.0 * Float64.PI * 2.0,
            anticlockwise: counterclockwise)
        invalidate(context, paint)
    }

    public func drawRect(x: Float64, y: Float64, width: Float64, height: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawRectInternal(this.context, x, y, width, height, v)
        }
    }

    public func drawRectInternal(context: CanvasRenderingContext2D, x: Float64, y: Float64, width: Float64,
        height: Float64, paint: Paint): Unit {
        updateContextAttributes(context, paint)
        context.beginPath()
        if (paint.isStroke()) {
            context.strokeRect(x, y, width, height)
        } else {
            context.fillRect(x, y, width, height)
        }
    }

    public func drawRoundRect(x: Float64, y: Float64, width: Float64, height: Float64, radius: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawRoundRectInternal(this.context, x, y, width, height, radius, v)
        }
    }

    private func drawRoundRectInternal(context: CanvasRenderingContext2D, x: Float64, y: Float64, width: Float64,
        height: Float64, radius: Float64, paint: Paint): Unit {
        updateContextAttributes(context, paint)
        context.beginPath()
        context.arc(x + radius, y + radius, radius, Float64.PI, Float64.PI * 3.0 / 2.0)
        context.lineTo(width - radius + x, y)
        context.arc(width - radius + x, radius + y, radius, Float64.PI * 3.0 / 2.0, Float64.PI * 2.0)
        context.lineTo(width + x, height + y - radius)
        context.arc(width - radius + x, height - radius + y, radius, 0.0, Float64.PI * 1.0 / 2.0)
        context.lineTo(radius + x, height + y)
        context.arc(radius + x, height - radius + y, radius, Float64.PI * 1.0 / 2.0, Float64.PI)
        context.closePath()
        invalidate(context, paint)
    }

    public func drawImage(image: ImageBitmap, sx: Float64, sy: Float64, sWidth: Float64, sHeight: Float64, dx: Float64,
        dy: Float64, dWidth: Float64, dHeight: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawImageInternal(this.context, image, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)
        }
    }

    public func drawImage(image: PixelMap, sx: Float64, sy: Float64, sWidth: Float64, sHeight: Float64, dx: Float64,
        dy: Float64, dWidth: Float64, dHeight: Float64, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            drawImageInternal(this.context, image, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)
        }
    }

    public func drawImageInternal(context: CanvasRenderingContext2D, image: ImageBitmap, sx: Float64, sy: Float64,
        sWidth: Float64, sHeight: Float64, dx: Float64, dy: Float64, dWidth: Float64, dHeight: Float64): Unit {
        context.beginPath()
        context.drawImage(image, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)
        context.stroke()
    }

    public func drawImageInternal(context: CanvasRenderingContext2D, image: PixelMap, sx: Float64, sy: Float64,
        sWidth: Float64, sHeight: Float64, dx: Float64, dy: Float64, dWidth: Float64, dHeight: Float64): Unit {
        context.beginPath()
        context.drawImage(image, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)
        context.stroke()
    }

    public func drawPath(path: Path2D, paint: ?Paint): Unit {
        if (let Some(v) <- paint) {
            if (v.isStroke()) {
                this.context.lineWidth(v.getStrokeWidth())
                this.context.strokeStyle(v.getColor())
                this.context.stroke(path)
            } else {
                if (v.getGradient().isSome()) {
                    this.context.fillStyle(v.getGradient()())
                } else {
                    this.context.fillStyle(v.getColor())
                }
                this.context.fill()
            }
        }
    }

    private func invalidate(context: CanvasRenderingContext2D, paint: Paint): Unit {
        if (paint.isStroke()) {
            context.stroke()
        } else {
            context.fill()
        }
    }

    public func measureText(text: String, paint: Paint): TextMetrics {
        return this.context.measureText(text)
    }

    public func rotate(x: Float64, y: Float64, angle: Float64, paint: Paint): Unit {
        rotateInternal(this.context, x, y, angle)
    }

    public func rotateInternal(context: CanvasRenderingContext2D, x: Float64, y: Float64, angle: Float64): Unit {
        context.translate(x, y)
        context.rotate(angle / 360.0 * Float64.PI * 2.0)
        context.translate(-x, -y)
    }

    public func scale(x: Float64, y: Float64, paint: Paint): Unit {
        this.context.scale(x, y)
    }

    public func getMatrix(): Matrix2D2 {
        return this.matrix
    }

    public func setMatrix(matrix: Matrix2D2): Unit {
        this.matrix = matrix
    }

    public func getContext(): CanvasRenderingContext2D {
        return this.context
    }

    public func clipRect(left: Float64, top: Float64, right: Float64, bottom: Float64): Unit {
        this.context.beginPath()
        this.context.rect(left, top, right, bottom)
        this.context.clip()
    }

    public func clipPath(path: Path2D): Unit {
        this.context.beginPath()
        this.context.clip()
    }

    public func drawColor(color: Color): Unit {
        this.context.fillStyle(color)
    }

    public func translate(x: Float64, y: Float64, paint: Paint): Unit {
        this.context.translate(x, y)
    }

    public func restore(paint!: Paint = Paint()): Unit {
        this.context.restore()
    }

    public func save(paint!: Paint = Paint()): Unit {
        this.context.save()
    }

    public func clear(width: Float64, height: Float64): Unit {
        //    this.context.clearRect(0.0, 0.0, this.context.width, this.context.height)
        this.context.clearRect(0.0, 0.0, width, height)
    }

    public func getPixelMap(width: Float64, height: Float64): PixelMap {
        //    return this.context.getPixelMap(0.0, 0.0, this.context.width, this.context.heiht)
        return this.context.getPixelMap(0.0, 0.0, width, height)
    }
}
