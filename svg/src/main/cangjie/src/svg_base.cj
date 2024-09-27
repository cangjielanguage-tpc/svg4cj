/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class SVGBase {
    static let DEFAULT_PICTURE_WIDTH: Int64 = 512
    static let DEFAULT_PICTURE_HEIGHT: Int64 = 512
    static let SQRT2: Float64 = 1.414213562373095
    static let externalFileResolverSingleton: SVGExternalFileResolver = SVGExternalFileResolver()
    static let enableInternalEntitiesSingleton: Bool = true
    var externalFileResolver: SVGExternalFileResolver = SVGExternalFileResolver()
    var enableInternalEntities: Bool
    var rootElement: Svg = Svg()
    var title: String = ""
    var desc: String = ""
    var renderDPI: Float64 = 96.0
    let cssRules: RuleSet = RuleSet()
    let idToElementMap: HashMap<String, SvgElementBase> = HashMap<String, SvgElementBase>()

    public init(enableInternalEntities: Bool, fileResolver: SVGExternalFileResolver) {
        this.enableInternalEntities = enableInternalEntities
        this.externalFileResolver = fileResolver
    }

    public static func getFromString(svg: String): SVGBase {
        return createParser().parseString(svg)
    }

    public static func getFromResource(media: OhosResource, callback: (SVGBase) -> Unit, abilityContext: AbilityContext): Unit {
        let resourceManager = ResourceManager.getResourceManager(getStageContext(abilityContext))
        let value: Array<UInt8> = resourceManager.getMediaContent(media, 100)
        let data = String.fromUtf8(value)
        let svgBase = getFromString(data)
        callback(svgBase)
    }

    public static func getFromRawfile(rawfileName: String, callback: (SVGBase) -> Unit, abilityContext: AbilityContext): Unit {
        let resourceManager = ResourceManager.getResourceManager(getStageContext(abilityContext))
        let value: Array<UInt8> = resourceManager.getRawFileContent(rawfileName)
        let data = String.fromUtf8(value)
        let svgBase = getFromString(data)
        callback(svgBase)
    }

    public func setRenderDPI(dpi: Float64): Unit {
        this.renderDPI = dpi
    }

    public func getRenderDPI(): Float64 {
        return this.renderDPI
    }

    protected static func createParser(): SVGParser {
        return SVGParserImpl().setInternalEntitiesEnabled(enableInternalEntitiesSingleton).setExternalFileResolver(
            externalFileResolverSingleton)
    }

    public func getRootElement(): Svg {
        return this.rootElement
    }

    public func setRootElement(rootElement: Svg): Unit {
        this.rootElement = rootElement
    }

    func resolveIRI(s: String): ?SvgObject {
        if (s == "") {
            return None
        }
        var iri: String = s
        iri = cssQuotedString(iri)
        if (iri.size > 1 && iri.startsWith("#")) {
            return getElementById(iri[1..])() as SvgObject
        }
        return None
    }

    private func cssQuotedString(s: String): String {
        var str: String = s
        if (str.startsWith("\"") && str.endsWith("\"")) {
            str = str[1..(str.size - 1)].replace("\\\"", "\"")
        } else if (str.startsWith("'") && str.endsWith("'")) {
            str = str[1..(str.size - 1)].replace("\\'", "'")
        }
        return str.replace("\\\n", "").replace("\\A", "\n")
    }

    func addCSSRules(ruleset: RuleSet): Unit {
        this.cssRules.addAll(ruleset)
    }

    func getCSSRules(): ArrayList<Rule> {
        return this.cssRules.getRules()
    }

    func hasCSSRules(): Bool {
        return !this.cssRules.isEmpty()
    }

    func clearRenderCSSRules(): Unit {
        this.cssRules.removeFromSource(Source.RenderOptions)
    }

    func setTitle(title: String): Unit {
        this.title = title
    }

    func setDesc(desc: String): Unit {
        this.desc = desc
    }

    func getElementById(id: String): ?SvgElementBase {
        if (id.size == 0 || id == "") {
            return None
        }
        if (id == this.rootElement.id) {
            return (this.rootElement as SvgElementBase)()
        }
        if (this.idToElementMap.contains(id)) {
            return this.idToElementMap.get(id)
        }
        let result: ?SvgElementBase = getElementById2((this.rootElement as SvgContainer)(), id)
        if (let Some(v) <- result) {
            this.idToElementMap.put(id, v)
        }
        return result
    }

    private func getElementById2(obj: SvgContainer, id: String): ?SvgElementBase {
        if (obj is SvgElementBase) {
            let elem: SvgElementBase = (obj as SvgElementBase)()
            if (id == elem.id) {
                return elem
            }
            for (i in 0..obj.getChildren().size) {
                let child = obj.getChildren()[i]
                if (!(child is SvgElementBase)) {
                    continue
                }
                let childElem: SvgElementBase = (child as SvgElementBase)()
                if (id == childElem.id) {
                    return childElem
                }
                if (let Some(child) <- child as SvgContainer) {
                    let found: ?SvgElementBase = getElementById2(child, id)
                    if (found.isSome()) {
                        return found
                    }
                }
            }
        }
        return None
    }

    private func getElementsByTagName(nodeName: String, res: ArrayList<SvgObject>, o: SvgObject): ArrayList<SvgObject> {
        var result: ArrayList<SvgObject> = res
        var obj: SvgObject = o
        if (result.isEmpty()) {
            result = ArrayList<SvgObject>()
        }
        obj = (this.rootElement as SvgObject)()

        if (obj.getNodeName() == nodeName) {
            result.append(obj)
        }
        if (let Some(obj) <- obj as SvgContainer) {
            let arr: ArrayList<SvgObject> = obj.getChildren()
            for (element in arr) {
                getElementsByTagName(nodeName, result, element)
            }
        }
        return result
    }
}

struct Units {
    static let px: String = "px"
    static let em: String = "em"
    static let ex: String = "ex"
    static let ins: String = "in"
    static let cm: String = "cm"
    static let mm: String = "mm"
    static let pt: String = "pt"
    static let pc: String = "pc"
    static let percent: String = "percent"
}

class GradientSpread <: Equatable<GradientSpread> {

    var val: String = ""

    public operator func ==(that: GradientSpread): Bool {
        return this.val == that.val
    }

    public operator func !=(that: GradientSpread): Bool {
        return !(this == that)
    }
}

public class Box <: Equatable<Box> {
    var minX: Float64
    var minY: Float64
    var width: Float64
    var height: Float64

    init(minX: Float64, minY: Float64, width: Float64, height: Float64) {
        this.minX = minX
        this.minY = minY
        this.width = width
        this.height = height
    }

    func copy(copy: Box): Unit {
        this.minX = copy.minX
        this.minY = copy.minY
        this.width = copy.width
        this.height = copy.height
    }

    static func fromLimits(minX: Float64, minY: Float64, maxX: Float64, maxY: Float64): Box {
        return Box(minX, minY, maxX - minX, maxY - minY)
    }

    func toRectF(): MyRect {
        return MyRect(left: this.minX, top: this.minY, right: maxX(), bottom: maxY())
    }

    func maxX(): Float64 {
        return this.minX + this.width
    }

    func maxY(): Float64 {
        return this.minY + this.height
    }

    func union(other: Box): Unit {
        if (other.minX < this.minX) {
            this.minX = other.minX
        }
        if (other.minY < this.minY) {
            this.minY = other.minY
        }
        if (other.maxX() > maxX()) {
            this.width = other.maxX() - this.minX
        }
        if (other.maxY() > maxY()) {
            this.height = other.maxY() - this.minY
        }
    }

    public operator func ==(that: Box): Bool {
        return this.minX == that.minX && this.minY == that.minY && this.width == that.width && this.height == that.
            height
    }

    public operator func !=(that: Box): Bool {
        return !(this == that)
    }

    public func toString(): String {
        return "[" + "${this.minX}" + " " + "${this.minY}" + " " + "${this.width}" + " " + "${this.height}" + "]"
    }
}

open class SvgPaint <: ToString & Equatable<SvgPaint> {
    public open func toString(): String {
        return ""
    }

    public operator func ==(that: SvgPaint): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: SvgPaint): Bool {
        return !refEq(this, that)
    }
}

public open class Svg <: SvgViewBoxContainer {
    var x: SVGLength = SVGLength()
    var y: SVGLength = SVGLength()
    var width: SVGLength = SVGLength()
    var height: SVGLength = SVGLength()
    public var version: String = ""

    public func getNodeName(): String {
        return "svg"
    }
}

public open class SvgViewBoxContainer <: SvgPreserveAspectRatioContainer {
    var viewBox: Box = Box(0.0, 0.0, 0.0, 0.0)
}

public open class SvgPreserveAspectRatioContainer <: SvgConditionalContainer {
    var preserveAspectRatio: ?PreserveAspectRatio = None
}

public open class SvgConditionalContainer <: SvgElement & SvgContainer & SvgConditional {
    var children: ArrayList<SvgObject> = ArrayList<SvgObject>()
    var requiredFeatures: HashSet<String> = HashSet<String>()
    var requiredExtensions: String = ""
    var systemLanguage: HashSet<String> = HashSet<String>()
    var requiredFormats: HashSet<String> = HashSet<String>()
    var requiredFonts: HashSet<String> = HashSet<String>()

    public func getChildren(): ArrayList<SvgObject> {
        return this.children
    }

    public open func addChild(elem: SvgObject): Unit {
        this.children.append(elem)
    }

    public func setRequiredFeatures(features: HashSet<String>): Unit {
        this.requiredFeatures = features
    }

    public func getRequiredFeatures(): HashSet<String> {
        return this.requiredFeatures
    }

    public func setRequiredExtensions(extensions: String): Unit {
        this.requiredExtensions = extensions
    }

    public func getRequiredExtensions(): String {
        return this.requiredExtensions
    }

    public func setSystemLanguage(languages: HashSet<String>): Unit {
        this.systemLanguage = languages
    }

    public func getSystemLanguage(): HashSet<String> {
        return HashSet<String>()
    }

    public func setRequiredFormats(mimeTypes: HashSet<String>) {
        this.requiredFormats = mimeTypes
    }

    public func getRequiredFormats(): HashSet<String> {
        return this.requiredFormats
    }

    public func setRequiredFonts(fontNames: HashSet<String>) {
        this.requiredFonts = fontNames
    }

    public func getRequiredFonts(): HashSet<String> {
        return this.requiredFonts
    }
}

public open class SvgObject <: ToString {
    var document: ?SVGBase = None
    var parent: ?SvgContainer = None
    public let types: String = ""

    public open func getNodeName(): String {
        return ""
    }

    public open func toString(): String {
        return types
    }
}

public interface SvgContainer {
    func getChildren(): ArrayList<SvgObject>

    func addChild(elem: SvgObject): Unit
}

public open class SvgElementBase <: SvgObject & Equatable<SvgElementBase> {
    var id: String = ""
    var spacePreserve: Bool = false
    var baseStyle: Style = Style()
    var style: ?Style = Option<Style>.None
    var classNames: ArrayList<String> = ArrayList<String>()

    public func toString(): String {
        return getNodeName()
    }

    public operator func ==(that: SvgElementBase): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: SvgElementBase): Bool {
        return !refEq(this, that)
    }
}

public open class SvgElement <: SvgElementBase {
    public var boundingBox: Box = Box(0.0, 0.0, 0.0, 0.0)
}

public interface SvgConditional {
    func setRequiredFeatures(features: HashSet<String>): Unit

    func getRequiredFeatures(): HashSet<String>

    func setRequiredExtensions(extensions: String): Unit

    func getRequiredExtensions(): String

    func setSystemLanguage(languages: HashSet<String>): Unit

    func getSystemLanguage(): HashSet<String>

    func setRequiredFormats(mimeTypes: HashSet<String>): Unit

    func getRequiredFormats(): HashSet<String>

    func setRequiredFonts(fontNames: HashSet<String>): Unit

    func getRequiredFonts(): HashSet<String>
}

class Colour <: SvgPaint {
    var colour: Color
    static let BLACK: Colour = Colour(Color(0x000000))
    static let TRANSPARENT: Colour = Colour(Color(0xFFFFFF))

    init(val: Color) {
        super()
        this.colour = val
    }

    public func toString(): String {
        return "#%08x ${this.colour.toUInt32().format("x")}"
    }
}

class CurrentColor <: SvgPaint {
    private static let instance: CurrentColor = CurrentColor()

    init() {
        super()
    }

    static func getInstance(): CurrentColor {
        return instance
    }
}

class PaintReference <: SvgPaint {
    var href: String
    var fallback: ?SvgPaint

    init(href: String, fallback: ?SvgPaint) {
        super()
        this.href = href
        this.fallback = fallback
    }

    public func toString(): String {
        return this.href + " " + "${this.fallback}"
    }
}

class SVGLength {
    var value: Float64 = 0.0
    var uni: String = ""
    static let ZERO: SVGLength = SVGLength()

    init() {}

    init(value: Float64, u!: String = "") {
        var uni: String = u
        this.value = value
        if (uni == "") {
            uni = Units.px
        }
        this.uni = uni
    }

    func floatValueBox(renderer: SVGRenderer): Float64 {
        match (this.uni) {
            case "em" => return this.value * renderer.getCurrentFontSize()
            case "ex" => return this.value * renderer.getCurrentFontXHeight()
            case "in" => return this.value * renderer.getDPI()
            case "cm" => return this.value * renderer.getDPI() / 2.54
            case "mm" => return this.value * renderer.getDPI() / 25.4
            case "pt" => return this.value * renderer.getDPI() / 72.0
            case "pc" => return this.value * renderer.getDPI() / 6.0
            case "percent" =>
                let viewPortUser: Box = renderer.getCurrentViewPortInUserUnits()
                if (viewPortUser == Box(0.0, 0.0, 0.0, 0.0)) {
                    return this.value
                } else {
                    return this.value * viewPortUser.width / 100.0
                }
            case "px" => return this.value
            case _ => return this.value
        }
    }

    func floatValueX(renderer: SVGRenderer): Float64 {
        match (this.uni) {
            case "em" => return this.value * renderer.getCurrentFontSize()
            case "ex" => return this.value * renderer.getCurrentFontXHeight()
            case "in" => return (px2vp(Length(this.value * renderer.getDPI(), unitType: LengthType.px)) ?? Length(0.0,
                unitType: LengthType.px)).value
            case "cm" => return (px2vp(Length((this.value * renderer.getDPI() / 2.54), unitType: LengthType.px)) ??
                Length(0.0, unitType: LengthType.px)).value
            case "mm" => return (px2vp(Length((this.value * renderer.getDPI() / 25.4), unitType: LengthType.px)) ??
                Length(0.0, unitType: LengthType.px)).value
            case "pt" => return (px2vp(Length((this.value * renderer.getDPI() / 72.0), unitType: LengthType.px)) ??
                Length(0.0, unitType: LengthType.px)).value
            case "pc" => return (px2vp(Length((this.value * renderer.getDPI() / 6.0), unitType: LengthType.px)) ??
                Length(0.0, unitType: LengthType.px)).value
            case "percent" =>
                let viewPortUser: Box = renderer.getCurrentViewPortInUserUnits()
                if (viewPortUser == Box(0.0, 0.0, 0.0, 0.0)) {
                    return (px2vp(Length(this.value, unitType: LengthType.px)) ?? Length(0.0, unitType: LengthType.px)).
                        value
                } else {
                    return (px2vp(Length((this.value * viewPortUser.width / 100.0), unitType: LengthType.px)) ?? Length(
                        0.0, unitType: LengthType.px)).value
                }
            case "px" => return (px2vp(Length(this.value, unitType: LengthType.px)) ?? Length(0.0,
                unitType: LengthType.px)).value
            case _ => return (px2vp(Length(this.value, unitType: LengthType.px)) ?? Length(0.0, unitType: LengthType.px)).
                value
        }
    }

    func floatValueY(renderer: SVGRenderer): Float64 {
        if (this.uni == Units.percent) {
            let viewPortUser: Box = renderer.getCurrentViewPortInUserUnits()
            if (viewPortUser == Box(0.0, 0.0, 0.0, 0.0)) {
                return (px2vp(Length(this.value, unitType: LengthType.px)) ?? Length(0.0, unitType: LengthType.px)).
                    value
            }
            return (px2vp(Length((this.value * viewPortUser.height / 100.0), unitType: LengthType.px)) ?? Length(0.0,
                unitType: LengthType.px)).value
        }
        return floatValueX(renderer)
    }

    func getFloatValue(): Float64 {
        return this.value
    }

    func floatValue(renderer: SVGRenderer, max!: Float64 = 0.0): Float64 {
        if (max != 0.0) {
            if (this.uni == Units.percent) {
                return this.value * max / 100.0
            }
            return floatValueX(renderer)
        } else {
            if (this.uni == Units.percent) {
                let viewPortUser: Box = renderer.getCurrentViewPortInUserUnits()
                if (viewPortUser == Box(0.0, 0.0, 0.0, 0.0)) {
                    return this.value
                }
                let w: Float64 = viewPortUser.width
                let h: Float64 = viewPortUser.height
                if (w == h) {
                    return this.value * w / 100.0
                }
                let n: Float64 = (sqrt(w * w + h * h) / SVGBase.SQRT2)
                return (px2vp(Length((this.value * n / 100.0), unitType: LengthType.px)) ?? Length(0.0,
                    unitType: LengthType.px)).value
            }
            return floatValueX(renderer)
        }
    }

    func floatValueWithDpi(dpi: Float64): Float64 {
        match (this.uni) {
            case "in" => return this.value * dpi
            case "cm" => return this.value * dpi / 2.54
            case "mm" => return this.value * dpi / 25.4
            case "pt" => return this.value * dpi / 72.0
            case "pc" => return this.value * dpi / 6.0
            case "px" => return this.value
            case "em" => return this.value
            case "ex" => return this.value
            case "percent" => return this.value
            case _ => return this.value
        }
    }

    func isZero(): Bool {
        return this.value == 0.0
    }

    func isNegative(): Bool {
        return this.value < 0.0
    }

    public func toString(): String {
        return "${this.value}" + this.uni.toString()
    }
}

class CSSClipRect {
    var top: SVGLength = SVGLength()
    var right: SVGLength = SVGLength()
    var bottom: SVGLength = SVGLength()
    var left: SVGLength = SVGLength()

    init() {}

    init(top: SVGLength, right: SVGLength, bottom: SVGLength, left: SVGLength) {
        this.top = top
        this.right = right
        this.bottom = bottom
        this.left = left
    }
}

open class SvgConditionalElement <: SvgElement & SvgConditional {
    var requiredFeatures: HashSet<String> = HashSet<String>()
    var requiredExtensions: String = ""
    var systemLanguage: HashSet<String> = HashSet<String>()
    var requiredFormats: HashSet<String> = HashSet<String>()
    var requiredFonts: HashSet<String> = HashSet<String>()

    public func setRequiredFeatures(features: HashSet<String>): Unit {
        this.requiredFeatures = features
    }

    public func getRequiredFeatures(): HashSet<String> {
        return this.requiredFeatures
    }

    public func setRequiredExtensions(extensions: String): Unit {
        this.requiredExtensions = extensions
    }

    public func getRequiredExtensions(): String {
        return this.requiredExtensions
    }

    public func setSystemLanguage(languages: HashSet<String>): Unit {
        this.systemLanguage = languages
    }

    public func getSystemLanguage(): HashSet<String> {
        return this.systemLanguage
    }

    public func setRequiredFormats(mimeTypes: HashSet<String>): Unit {
        this.requiredFormats = mimeTypes
    }

    public func getRequiredFormats(): HashSet<String> {
        return this.requiredFormats
    }

    public func setRequiredFonts(fontNames: HashSet<String>): Unit {
        this.requiredFonts = fontNames
    }

    public func getRequiredFonts(): HashSet<String> {
        return this.requiredFonts
    }
}

interface HasTransform {
    func setTransform(matrix: ?Matrix2D2): Unit
}

open class Group <: SvgConditionalContainer & HasTransform {
    var transform: ?Matrix2D2 = None

    public func setTransform(transform: ?Matrix2D2): Unit {
        this.transform = transform
    }

    public open func getNodeName(): String {
        return "group"
    }
}

interface NotDirectlyRendered {}

class Defs <: Group & NotDirectlyRendered {
    public func getNodeName(): String {
        return "defs"
    }
}

open class GraphicsElement <: SvgConditionalElement & HasTransform {
    var transform: ?Matrix2D2 = None

    public func setTransform(transform: ?Matrix2D2): Unit {
        this.transform = transform
    }
}

class A <: Group {
    var href: String = ""

    public func getNodeName(): String {
        return "a"
    }
}

class Use <: Group {
    var href: String = ""
    var x: SVGLength = SVGLength()
    var y: SVGLength = SVGLength()
    var width: SVGLength = SVGLength()
    var height: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "use"
    }
}

class Path2 <: GraphicsElement {
    var d: ?PathDefinition = None
    var pathLength: Float64 = 0.0

    public func getNodeName(): String {
        return "path"
    }
}

class Rect2 <: GraphicsElement {
    var x: SVGLength = SVGLength()
    var y: SVGLength = SVGLength()
    var width: SVGLength = SVGLength(100.0)
    var height: SVGLength = SVGLength(100.0)
    var rx: SVGLength = SVGLength()
    var ry: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "rect"
    }
}

class Circle2 <: GraphicsElement {
    var cx: SVGLength = SVGLength()
    var cy: SVGLength = SVGLength()
    var r: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "circle"
    }
}

class Ellipse2 <: GraphicsElement {
    var cx: SVGLength = SVGLength()
    var cy: SVGLength = SVGLength()
    var rx: SVGLength = SVGLength()
    var ry: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "ellipse"
    }
}

class Line2 <: GraphicsElement {
    var x1: SVGLength = SVGLength()
    var y1: SVGLength = SVGLength()
    var x2: SVGLength = SVGLength()
    var y2: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "line"
    }
}

open class PolyLine <: GraphicsElement {
    var points: ArrayList<Float64> = ArrayList<Float64>()

    public open func getNodeName(): String {
        return "polyline"
    }
}

class Polygon2 <: PolyLine {
    public func getNodeName(): String {
        return "polygon"
    }
}

interface TextRoot {}

interface TextChild {
    func setTextRoot(obj: TextRoot): Unit

    func getTextRoot(): TextRoot
}

open class TextContainer <: SvgConditionalContainer {
    public func addChild(elem: SvgObject): Unit {
        try {
            this.children.append(elem)
        } catch (e: Exception) {
        }
    }
}

open class TextPositionedContainer <: TextContainer {
    var x: ArrayList<SVGLength> = ArrayList<SVGLength>()
    var y: ArrayList<SVGLength> = ArrayList<SVGLength>()
    var dx: ArrayList<SVGLength> = ArrayList<SVGLength>()
    var dy: ArrayList<SVGLength> = ArrayList<SVGLength>()
}

class Text2 <: TextPositionedContainer & TextRoot & HasTransform {
    var transform: ?Matrix2D2 = None
    var text: String = ""

    public func setTransform(transform: ?Matrix2D2): Unit {
        this.transform = transform
    }

    public func getNodeName(): String {
        return "text"
    }
}

class TSpan <: TextPositionedContainer & TextChild {
    private var textRoot: TextRoot = Text2()
    var text: String = ""

    public func setTextRoot(obj: TextRoot) {
        this.textRoot = obj
    }

    public func getTextRoot(): TextRoot {
        return this.textRoot
    }

    public func getNodeName(): String {
        return "tspan"
    }
}

class TextSequence <: SvgObject & TextChild {
    var text: String
    private var textRoot: TextRoot = Text2()

    init(text: String) {
        super()
        this.text = text
    }

    public func toString(): String {
        return "TextChild: '" + this.text + "'"
    }

    public func setTextRoot(obj: TextRoot): Unit {
        this.textRoot = obj
    }

    public func getTextRoot(): TextRoot {
        return this.textRoot
    }
}

class TRef <: TextContainer & TextChild {
    var href: String = ""
    private var textRoot: TextRoot = Text2()

    public func setTextRoot(obj: TextRoot): Unit {
        this.textRoot = obj
    }

    public func getTextRoot(): TextRoot {
        return this.textRoot
    }

    public func getNodeName(): String {
        return "tref"
    }
}

class TextPath <: TextContainer & TextChild {
    var href: String = ""
    var startOffset: SVGLength = SVGLength()
    private var textRoot: TextRoot = Text2()

    public func setTextRoot(obj: TextRoot): Unit {
        this.textRoot = obj
    }

    public func getTextRoot(): TextRoot {
        return this.textRoot
    }

    public func getNodeName(): String {
        return "textPath"
    }
}

class Switch <: Group {
    public func getNodeName(): String {
        return "switch"
    }
}

class Symbol <: SvgViewBoxContainer & NotDirectlyRendered {
    public func getNodeName(): String {
        return "symbol"
    }
}

class Marker <: SvgViewBoxContainer & NotDirectlyRendered {
    var markerUnitsAreUser: Bool = false
    var refX: SVGLength = SVGLength()
    var refY: SVGLength = SVGLength()
    var markerWidth: SVGLength = SVGLength()
    var markerHeight: SVGLength = SVGLength()
    var orient: Float64 = 0.0

    public func getNodeName(): String {
        return "marker"
    }
}

open class GradientElement <: SvgElementBase & SvgContainer & Equatable<GradientElement> {
    var children: ArrayList<SvgObject> = ArrayList<SvgObject>()
    var gradientUnitsAreUser: Bool = false
    var gradientTransform: ?Matrix2D2 = None
    var spreadMethod: GradientSpread = GradientSpread()
    var href: String = ""

    public func getChildren(): ArrayList<SvgObject> {
        return this.children
    }

    public func addChild(elem: SvgObject): Unit {
        if (elem is Stop) {
            this.children.append(elem)
        } else {
            throw SVGParseException("Gradient elements cannot contain " + "${elem}" + " elements.")
        }
    }

    public operator func ==(that: GradientElement): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: GradientElement): Bool {
        return !refEq(this, that)
    }
}

class Stop <: SvgElementBase & SvgContainer {
    var offset: Int64 = 0

    public func getChildren(): ArrayList<SvgObject> {
        return ArrayList<SvgObject>()
    }

    public func addChild(elem: SvgObject): Unit {
    }

    public func getNodeName(): String {
        return "stop"
    }
}

class SvgLinearGradient <: GradientElement {
    var x1: SVGLength = SVGLength()
    var y1: SVGLength = SVGLength()
    var x2: SVGLength = SVGLength()
    var y2: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "linearGradient"
    }
}

class SvgRadialGradient <: GradientElement {
    var cx: SVGLength = SVGLength()
    var cy: SVGLength = SVGLength()
    var r: SVGLength = SVGLength()
    var fx: SVGLength = SVGLength()
    var fy: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "radialGradient"
    }
}

class ClipPath <: Group & NotDirectlyRendered {
    var clipPathUnitsAreUser: Bool = false

    public func getNodeName(): String {
        return "clipPath"
    }
}

class Pattern <: SvgViewBoxContainer & NotDirectlyRendered & Equatable<Pattern> {
    var patternUnitsAreUser: Bool = false
    var patternContentUnitsAreUser: Bool = false
    var patternTransform: ?Matrix2D2 = None
    var x: SVGLength = SVGLength()
    var y: SVGLength = SVGLength()
    var width: SVGLength = SVGLength()
    var height: SVGLength = SVGLength()
    var href: String = ""

    public func getNodeName(): String {
        return "pattern"
    }

    public operator func ==(that: Pattern): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: Pattern): Bool {
        return !refEq(this, that)
    }
}

class Image2 <: SvgPreserveAspectRatioContainer & HasTransform {
    var href: String = ""
    var x: SVGLength = SVGLength()
    var y: SVGLength = SVGLength()
    var width: SVGLength = SVGLength()
    var height: SVGLength = SVGLength()
    var transform: ?Matrix2D2 = None
    let translateX: SVGLength = SVGLength()
    let translateY: SVGLength = SVGLength()

    public func setTransform(transform: ?Matrix2D2): Unit {
        this.transform = transform
    }

    public func getNodeName(): String {
        return "image"
    }
}

class View <: SvgViewBoxContainer & NotDirectlyRendered {
    static let NODE_NAME: String = "view"

    public func getNodeName(): String {
        return View.NODE_NAME
    }
}

class Mask <: SvgConditionalContainer & NotDirectlyRendered {
    var maskUnitsAreUser: Bool = false
    var boolean: Bool = false
    var maskContentUnitsAreUser: Bool = false
    var x: SVGLength = SVGLength()
    var y: SVGLength = SVGLength()
    var width: SVGLength = SVGLength()
    var height: SVGLength = SVGLength()

    public func getNodeName(): String {
        return "mask"
    }
}

class SolidColor <: SvgElementBase & SvgContainer {
    public func getChildren(): ArrayList<SvgObject> {
        return ArrayList<SvgObject>()
    }

    public func addChild(elem: SvgObject): Unit {
    }

    public func getNodeName(): String {
        return "solidColor"
    }
}

interface PathInterface {
    func moveTo(x: Float64, y: Float64): Unit

    func lineTo(x: Float64, y: Float64): Unit

    func cubicTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64, x3: Float64, y3: Float64): Unit

    func quadTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64): Unit

    func arcTo(rx: Float64, ry: Float64, xAxisRotation: Float64, largeArcFlag: Bool, sweepFlag: Bool, x: Float64, y: Float64): Unit

    func close(): Unit
}

class PathDefinition <: PathInterface {
    private var commands: Array<Byte>
    private var commandsLength: Int64 = 0
    private var coords: Array<Float64>
    private var coordsLength: Int64 = 0
    private static let MOVETO: Byte = 0
    private static let LINETO: Byte = 1
    private static let CUBICTO: Byte = 2
    private static let QUADTO: Byte = 3
    private static let ARCTO: Byte = 4
    private static let CLOSE: Byte = 8
    var d: String = ""

    init() {
        this.commands = Array<Byte>(8, item: 0)
        this.coords = Array<Float64>(16, item: 0.0)
    }

    func isEmpty(): Bool {
        return this.commandsLength == 0
    }

    private func addCommand(value: Byte): Unit {
        if (this.commandsLength == this.commands.size) {
            let newCommands: Array<Byte> = Array<Byte>(this.commands.size * 2, item: 0)
            for (i in 0..this.commands.size) {
                newCommands[i] = this.commands[i]
            }
            this.commands = newCommands
        }
        this.commands[this.commandsLength] = value
        this.commandsLength++
    }

    private func coordsEnsure(num: Int64): Unit {
        if (this.coords.size < (this.coordsLength + num)) {
            let newCoords: Array<Float64> = Array<Float64>(this.coords.size * 2, item: 0.0)
            for (i in 0..this.coords.size) {
                newCoords[i] = this.coords[i]
            }
            this.coords = newCoords
        }
    }

    public func moveTo(x: Float64, y: Float64): Unit {
        addCommand(PathDefinition.MOVETO)
        coordsEnsure(2)
        this.coords[this.coordsLength] = x
        this.coordsLength++
        this.coords[this.coordsLength] = y
        this.coordsLength++
    }

    public func lineTo(x: Float64, y: Float64): Unit {
        addCommand(PathDefinition.LINETO)
        coordsEnsure(2)
        this.coords[this.coordsLength] = x
        this.coordsLength++
        this.coords[this.coordsLength] = y
        this.coordsLength++
    }

    public func cubicTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64, x3: Float64, y3: Float64): Unit {
        addCommand(PathDefinition.CUBICTO)
        coordsEnsure(6)
        this.coords[this.coordsLength] = x1
        this.coordsLength++
        this.coords[this.coordsLength] = y1
        this.coordsLength++
        this.coords[this.coordsLength] = x2
        this.coordsLength++
        this.coords[this.coordsLength] = y2
        this.coordsLength++
        this.coords[this.coordsLength] = x3
        this.coordsLength++
        this.coords[this.coordsLength] = y3
        this.coordsLength++
    }

    public func quadTo(x1: Float64, y1: Float64, x2: Float64, y2: Float64): Unit {
        addCommand(PathDefinition.QUADTO)
        coordsEnsure(4)
        this.coords[this.coordsLength] = x1
        this.coordsLength++
        this.coords[this.coordsLength] = y1
        this.coordsLength++
        this.coords[this.coordsLength] = x2
        this.coordsLength++
        this.coords[this.coordsLength] = y2
        this.coordsLength++
    }

    public func arcTo(rx: Float64, ry: Float64, xAxisRotation: Float64, largeArcFlag: Bool, sweepFlag: Bool, x: Float64,
        y: Float64): Unit {
        let arc: Byte = PathDefinition.ARCTO | if (largeArcFlag) {
            2
        } else {
            0
        } | if (sweepFlag) {
            1
        } else {
            0
        }
        addCommand(arc)
        coordsEnsure(5)
        this.coords[this.coordsLength] = rx
        this.coordsLength++
        this.coords[this.coordsLength] = ry
        this.coordsLength++
        this.coords[this.coordsLength] = xAxisRotation
        this.coordsLength++
        this.coords[this.coordsLength] = x
        this.coordsLength++
        this.coords[this.coordsLength] = y
        this.coordsLength++
    }

    public func close(): Unit {
        addCommand(PathDefinition.CLOSE)
    }

    func enumeratePath(handler: PathInterface): Unit {
        var coordsPos: Int64 = 0
        for (i in 0..this.commandsLength) {
            let command: Byte = this.commands[i]
            match (command) {
                case 0 =>
                    let opt1 = coordsPos
                    coordsPos++
                    let opt2 = coordsPos
                    coordsPos++
                    handler.moveTo(this.coords[opt1], this.coords[opt2])
                case 1 =>
                    let opt1 = coordsPos
                    coordsPos++
                    let opt2 = coordsPos
                    coordsPos++
                    handler.lineTo(this.coords[opt1], this.coords[opt2])
                case 2 =>
                    let opt1 = coordsPos
                    coordsPos++
                    let opt2 = coordsPos
                    coordsPos++
                    let opt3 = coordsPos
                    coordsPos++
                    let opt4 = coordsPos
                    coordsPos++
                    let opt5 = coordsPos
                    coordsPos++
                    let opt6 = coordsPos
                    coordsPos++
                    handler.cubicTo(this.coords[opt1], this.coords[opt2], this.coords[opt3], this.coords[opt4],
                        this.coords[opt5], this.coords[opt6])
                case 3 =>
                    let opt1 = coordsPos
                    coordsPos++
                    let opt2 = coordsPos
                    coordsPos++
                    let opt3 = coordsPos
                    coordsPos++
                    let opt4 = coordsPos
                    coordsPos++
                    handler.quadTo(this.coords[opt1], this.coords[opt2], this.coords[opt3], this.coords[opt4])
                case 8 => handler.close()
                case _ =>
                    let largeArcFlag: Bool = (command & 2) != 0
                    let sweepFlag: Bool = (command & 1) != 0
                    let opt1 = coordsPos
                    coordsPos++
                    let opt2 = coordsPos
                    coordsPos++
                    let opt3 = coordsPos
                    coordsPos++
                    let opt4 = coordsPos
                    coordsPos++
                    let opt5 = coordsPos
                    coordsPos++
                    handler.arcTo(this.coords[opt1], this.coords[opt2], this.coords[opt3], largeArcFlag, sweepFlag,
                        this.coords[opt4], this.coords[opt5])
            }
        }
    }
}
