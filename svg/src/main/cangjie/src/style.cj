/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class Style {
    var specifiedFlags: Int64 = 0
    var fill: SvgPaint = Colour.BLACK
    var fillRule: String = ""
    var fillOpacity: Float64 = 0.0
    var stroke: SvgPaint = Colour.BLACK
    var strokeOpacity: Float64 = 0.0
    var strokeWidth: SVGLength = SVGLength()
    var strokeLineCap: LineCap = LineCap.Butt
    var strokeLineJoin: LineJoin = LineJoin.Bevel
    var strokeMiterLimit: Float64 = 0.0
    var strokeDashArray: ArrayList<SVGLength> = ArrayList<SVGLength>()
    var strokeDashOffset: SVGLength = SVGLength()

    var opacity: Float64 = 0.0 // master opacity of both stroke and fill
    var color: Colour = Colour.BLACK

    var fontFamily: ArrayList<String> = ArrayList<String>()
    var fontSize: SVGLength = SVGLength()
    var fontWeight: Float64 = 0.0
    var fontStyle: FontStyle = FontStyle.Normal
    var fontStretch: Float64 = 0.0
    var textDecoration: String = ""
    var direction: String = ""

    var textAnchor: String = ""

    var overflow: Bool = false // true if overflow visible
    var clip: ?CSSClipRect = None

    var markerStart: String = ""
    var markerMid: String = ""
    var markerEnd: String = ""

    var display: Bool = false // true if we should display
    var visibility: Bool = false // true if visible

    var stopColor: SvgPaint = Colour.BLACK
    var stopOpacity: Float64 = 0.0

    var clipPath: String = ""
    var clipRule: String = ""

    var mask: String = ""

    var solidColor: SvgPaint = SvgPaint()
    var solidOpacity: Float64 = 0.0

    var viewportFill: SvgPaint = SvgPaint()
    var viewportFillOpacity: Float64 = 0.0

    var vectorEffect: String = ""

    var imageRendering: String = ""

    var isolation: String = ""
    var mixBlendMode: String = ""

    var fontKerning: String = ""
    var fontVariantLigatures: ?CSSFontFeatureSettings = None
    var fontVariantPosition: ?CSSFontFeatureSettings = None
    var fontVariantCaps: ?CSSFontFeatureSettings = None
    var fontVariantNumeric: ?CSSFontFeatureSettings = None
    var fontVariantEastAsian: ?CSSFontFeatureSettings = None
    var fontFeatureSettings: ?CSSFontFeatureSettings = None
    var fontVariationSettings: ?CSSFontFeatureSettings = None
    var writingMode: WritingMode = WritingMode.lr
    var glyphOrientationVertical: GlypOrientationVertical = GlypOrientationVertical.angle0
    var textOrientation: TextOrientation = TextOrientation.mixed

    var letterSpacing: SVGLength = SVGLength()
    var wordSpacing: SVGLength = SVGLength()

    static let FONT_WEIGHT_MIN: Float64 = 1.0
    static let FONT_WEIGHT_NORMAL: Float64 = 400.0
    static let FONT_WEIGHT_BOLD: Float64 = 700.0
    static let FONT_WEIGHT_MAX: Float64 = 1000.0
    static let FONT_WEIGHT_LIGHTER: Float64 = Float64.Min
    static let FONT_WEIGHT_BOLDER: Float64 = Float64.Max
    static let FONT_STRETCH_MIN: Float64 = 0.0
    static let FONT_STRETCH_NORMAL: Float64 = 100.0

    static let SPECIFIED_FILL = (1 << 0)
    static let SPECIFIED_FILL_RULE = (1 << 1)
    static let SPECIFIED_FILL_OPACITY = (1 << 2)
    static let SPECIFIED_STROKE = (1 << 3)
    static let SPECIFIED_STROKE_OPACITY = (1 << 4)
    static let SPECIFIED_STROKE_WIDTH = (1 << 5)
    static let SPECIFIED_STROKE_LINECAP = (1 << 6)
    static let SPECIFIED_STROKE_LINEJOIN = (1 << 7)
    static let SPECIFIED_STROKE_MITERLIMIT = (1 << 8)
    static let SPECIFIED_STROKE_DASHARRAY = (1 << 9)
    static let SPECIFIED_STROKE_DASHOFFSET = (1 << 10)
    static let SPECIFIED_OPACITY = (1 << 11)
    static let SPECIFIED_COLOR = (1 << 12)
    static let SPECIFIED_FONT_FAMILY = (1 << 13)
    static let SPECIFIED_FONT_SIZE = (1 << 14)
    static let SPECIFIED_FONT_WEIGHT = (1 << 15)
    static let SPECIFIED_FONT_STYLE = (1 << 16)
    static let SPECIFIED_TEXT_DECORATION = (1 << 17)
    static let SPECIFIED_TEXT_ANCHOR = (1 << 18)
    static let SPECIFIED_OVERFLOW = (1 << 19)
    static let SPECIFIED_CLIP = (1 << 20)
    static let SPECIFIED_MARKER_START = (1 << 21)
    static let SPECIFIED_MARKER_MID = (1 << 22)
    static let SPECIFIED_MARKER_END = (1 << 23)
    static let SPECIFIED_DISPLAY = (1 << 24)
    static let SPECIFIED_VISIBILITY = (1 << 25)
    static let SPECIFIED_STOP_COLOR = (1 << 26)
    static let SPECIFIED_STOP_OPACITY = (1 << 27)
    static let SPECIFIED_CLIP_PATH = (1 << 28)
    static let SPECIFIED_CLIP_RULE = (1 << 29)
    static let SPECIFIED_MASK = (1 << 30)
    static let SPECIFIED_SOLID_COLOR = (1 << 31)
    static let SPECIFIED_SOLID_OPACITY = (1 << 32)
    static let SPECIFIED_VIEWPORT_FILL = (1 << 33)
    static let SPECIFIED_VIEWPORT_FILL_OPACITY = (1 << 34)
    static let SPECIFIED_VECTOR_EFFECT = (1 << 35)
    static let SPECIFIED_DIRECTION = (1 << 36)
    static let SPECIFIED_IMAGE_RENDERING = (1 << 37)
    static let SPECIFIED_ISOLATION = (1 << 38)
    static let SPECIFIED_MIX_BLEND_MODE = (1 << 39)
    static let SPECIFIED_FONT_VARIANT_LIGATURES = (1 << 40)
    static let SPECIFIED_FONT_VARIANT_POSITION = (1 << 41)
    static let SPECIFIED_FONT_VARIANT_CAPS = (1 << 42)
    static let SPECIFIED_FONT_VARIANT_NUMERIC = (1 << 43)
    static let SPECIFIED_FONT_VARIANT_EAST_ASIAN = (1 << 44)
    static let SPECIFIED_FONT_FEATURE_SETTINGS = (1 << 45)
    static let SPECIFIED_WRITING_MODE = (1 << 46)
    static let SPECIFIED_GLYPH_ORIENTATION_VERTICAL = (1 << 47)
    static let SPECIFIED_TEXT_ORIENTATION = (1 << 48)
    static let SPECIFIED_FONT_KERNING = (1 << 49)
    static let SPECIFIED_FONT_VARIATION_SETTINGS = (1 << 50)
    static let SPECIFIED_FONT_STRETCH = (1 << 51)
    static let SPECIFIED_LETTER_SPACING = (1 << 52)
    static let SPECIFIED_WORD_SPACING = (1 << 53)

    static func getDefaultStyle(): Style {
        let def = Style()
        def.fill = Colour.BLACK
        def.fillRule = FillRule().NonZero
        def.fillOpacity = 1.0
        def.stroke = Colour.BLACK
        def.strokeOpacity = 1.0
        def.strokeWidth = SVGLength(1.0)
        def.strokeLineCap = LineCap.Butt
        def.strokeLineJoin = LineJoin.Miter
        def.strokeMiterLimit = 4.0
        def.strokeDashArray = ArrayList<SVGLength>()
        def.strokeDashOffset = SVGLength.ZERO
        def.opacity = 1.0
        def.color = Colour.BLACK
        def.fontFamily = ArrayList<String>()
        def.fontSize = SVGLength(12.0, u: Units.pt)
        def.fontWeight = FONT_WEIGHT_NORMAL
        def.fontStyle = FontStyle.Normal
        def.fontStretch = FONT_STRETCH_NORMAL
        def.textDecoration = TextDecoration().None
        def.direction = TextDirection().TR
        def.textAnchor = TextAnchor().Start
        def.overflow = true
        def.clip = CSSClipRect()
        def.markerStart = ""
        def.markerMid = ""
        def.markerEnd = ""
        def.display = true
        def.visibility = true
        def.stopColor = Colour.BLACK
        def.stopOpacity = 1.0
        def.clipPath = ""
        def.clipRule = FillRule().NonZero
        def.mask = ""
        def.solidColor = SvgPaint()
        def.solidOpacity = 1.0
        def.viewportFill = SvgPaint()
        def.viewportFillOpacity = 1.0
        def.vectorEffect = VectorEffect().None
        def.imageRendering = RenderQuality().auto
        def.isolation = Isolation().auto
        def.mixBlendMode = CSSBlendMode.normal
        def.fontKerning = FontKerning.auto
        def.letterSpacing = SVGLength.ZERO
        def.wordSpacing = SVGLength.ZERO
        def.writingMode = WritingMode.horizontal_tb
        def.glyphOrientationVertical = GlypOrientationVertical.auto
        def.textOrientation = TextOrientation.mixed
        return def
    }

    static func processStyleProperty(style: Style, localName: String, val: String): Unit {
        if (val.size != 0) {
            if (val != "inherit") {
                match (CSSBlendMode().fromString(localName)) {
                    case "fill" =>
                        style.fill = parsePaintSpecifier(val)
                        style.specifiedFlags |= 1
                    case "fill_rule" =>
                        style.fillRule = Rule(val)
                        style.specifiedFlags |= 2
                    case _ => ()
                }
            }
        }
    }

    static func parsePaintSpecifier(v: String): SvgPaint {
        var val: String = v
        if (val.startsWith("url(")) {
            let closeBracket: ?Int64 = val.indexOf(")")
            var href: String
            if (let Some(v) <- closeBracket) {
                href = val[4..v].trimAscii()
                var fallback: SvgPaint = SvgPaint()
                val = val[(v + 1)..].trimAscii()
                if (val.size > 0) {
                    fallback = parseColourSpecifer(val)
                }
                return PaintReference(href, fallback)
            } else {
                href = val[4..].trimAscii()
                return PaintReference(href, SvgPaint())
            }
        } else {
            return parseColourSpecifer(val)
        }
    }

    private static func parseColourSpecifer(val: String): SvgPaint {
        match (val) {
            case "none" => return Colour.TRANSPARENT
            case "currentColor" => return CurrentColor.getInstance()
            case _ => try {
                return parseColour(Color(UInt32.parse(val)))
            } catch (var4: SVGParseException) {
                return SvgPaint()
            }
        }
    }

    static func parseFillRule(val: String): String {
        if ("nonzero" == val) {
            return FillRule().NonZero
        }
        if ("evenodd" == val) {
            return FillRule().EvenOdd
        }
        return ""
    }

    private static func parseColour(val: Color): Colour {
        return Colour(val)
    }

    func resetNonInheritingProperties(isRootSVG: Bool): Unit {
        this.display = true
        this.overflow = isRootSVG
        this.clip = CSSClipRect()
        this.clipPath = ""
        this.opacity = 1.0
        this.stopColor = Colour.BLACK
        this.stopOpacity = 1.0
        this.mask = ""
        this.solidColor = SvgPaint()
        this.solidOpacity = 1.0
        this.viewportFill = SvgPaint()
        this.viewportFillOpacity = 1.0
        this.vectorEffect = VectorEffect().None
        this.isolation = Isolation().auto
        this.mixBlendMode = CSSBlendMode.normal
    }
}

class CSSBlendMode {
    static let normal = "normal"
    static let multiply = "multiply"
    static let screen = "screen"
    static let overlay = "overlay"
    static let darken = "darken"
    static let lighten = "lighten"
    static let color_dodge = "color_dodge"
    static let color_burn = "color_burn"
    static let hard_light = "hard_light"
    static let soft_light = "soft_light"
    static let difference = "difference"
    static let exclusion = "exclusion"
    static let hue = "hue"
    static let saturation = "saturation"
    static let color = "color"
    static let luminosity = "luminosity"
    static let UNSUPPORTED = "UNSUPPORTED"
    private let cache: HashMap<String, String> = HashMap<String, String>()

    init() {
        for ((k, v) in cache) {
            if (v != CSSBlendMode.UNSUPPORTED) {
                this.cache.put(k.replace("_", "-"), v)
            }
        }
    }

    public func fromString(str: String): String {
        let mode: ?String = this.cache.get(str)
        return mode ?? CSSBlendMode.UNSUPPORTED
    }
}

public class FontKerning {
    static let auto: String = "auto"
    static let normal: String = "normal"
    static let none: String = "none"
}

struct FillRule {
    let NonZero: String = "NonZero"
    let EvenOdd: String = "EvenOdd"
}

enum LineCap {
    | Butt
    | Round
    | Square
}

enum LineJoin {
    | Miter
    | Round
    | Bevel
}

struct TextAnchor {
    let Start: String = "Start"
    let Middle: String = "Middle"
    let End: String = "End"
}

struct TextDecoration {
    let None: String = "None"
    let Underline: String = "Underline"
    let Overline: String = "Overline"
    let LineThrough: String = "LineThrough"
    let Blink: String = "Blink"
}

struct TextDirection {
    let TR: String = "LTR"
    let TL: String = "RTL"
}

struct VectorEffect {
    let None: String = "None"
    let NonScalingStroke: String = "NonScalingStroke"
}

struct RenderQuality {
    let auto: String = "auto"
    let optimizeQuality: String = "optimizeQuality"
    let optimizeSpeed: String = "optimizeSpeed"
}

enum WritingMode {
    | lr_tb
    | rl_tb
    | tb_rl
    | lr
    | rl
    | tb
    | horizontal_tb
    | vertical_rl
    | vertical_lr
}

enum GlypOrientationVertical {
    | auto
    | angle0
    | angle90
    | angle180
    | angle270
}

enum TextOrientation {
    | mixed
    | upright
    | sideways
}

struct Isolation {
    let auto: String = "auto"
    let isolate: String = "isolate"
}
