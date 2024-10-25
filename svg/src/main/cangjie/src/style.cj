/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

public class Style {
    var specifiedFlags: Int64 = 0
    var fill: ?SvgPaint = Colour.BLACK
    var fillRule: String = ""
    var fillOpacity: Float64 = 1.0
    var stroke: ?SvgPaint = Colour.BLACK
    var strokeOpacity: Float64 = 0.0
    var strokeWidth: SVGLength = SVGLength()
    var strokeLineCap: ?LineCap = None
    var strokeLineJoin: ?LineJoin = None
    var strokeMiterLimit: Float64 = 0.0
    var strokeDashArray: ArrayList<SVGLength> = ArrayList<SVGLength>()
    var strokeDashOffset: SVGLength = SVGLength()

    var opacity: Float64 = 1.0 // master opacity of both stroke and fill
    var color: Colour = Colour.BLACK

    var fontFamily: ArrayList<String> = ArrayList<String>()
    var fontSize: SVGLength = SVGLength()
    var fontWeight: Float64 = 0.0
    var fontStyle: ?FontStyle = None
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

    var solidColor: ?SvgPaint = None
    var solidOpacity: Float64 = 0.0

    var viewportFill: ?SvgPaint = None
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
        def.stroke = None
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
        def.direction = TextDirection().LTR
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
                match (localName) {
                    case "fill" =>
                        style.fill = parsePaintSpecifier(val)
                        if (style.fill.isSome()) {
                            style.specifiedFlags |= SPECIFIED_FILL
                        }
                    case "fill_rule" =>
                        style.fillRule = parseFillRule(val)
                        if (style.fillRule != "") {
                            style.specifiedFlags |= SPECIFIED_FILL_RULE
                        }
                    case "fill_opacity" =>
                        style.fillOpacity = parseOpacity(val)
                        if (style.fillOpacity != 0.0) {
                            style.specifiedFlags |= SPECIFIED_FILL_OPACITY
                        }
                    case "stroke" =>
                        style.stroke = parsePaintSpecifier(val)
                        if (style.stroke.isSome()) {
                            style.specifiedFlags |= SPECIFIED_STROKE
                        }
                    case "stroke_opacity" =>
                        style.strokeOpacity = parseOpacity(val)
                        if (style.strokeOpacity != 0.0) {
                            style.specifiedFlags |= SPECIFIED_STROKE_OPACITY
                        }
                    case "stroke_width" =>
                        style.strokeWidth = SVGParserImpl.parseLength(val)
                        style.specifiedFlags |= SPECIFIED_STROKE_WIDTH
                    case "stroke_linecap" =>
                        style.strokeLineCap = parseStrokeLineCap(val)
                        if (style.strokeLineCap.isSome()) {
                            style.specifiedFlags |= SPECIFIED_STROKE_LINECAP
                        }
                    case "stroke_linejoin" =>
                        style.strokeLineJoin = parseStrokeLineJoin(val)
                        if (style.strokeLineJoin.isSome()) {
                            style.specifiedFlags |= SPECIFIED_STROKE_LINEJOIN
                        }
                    case "stroke_miterlimit" =>
                        style.strokeMiterLimit = SVGParserImpl.parseFloat(val)
                        style.specifiedFlags |= SPECIFIED_STROKE_MITERLIMIT
                    case "stroke_dasharray" =>
                        if (val == "") {
                            style.specifiedFlags |= SPECIFIED_STROKE_DASHARRAY
                        }
                        style.strokeDashArray = parseStrokeDashArray(val)
                        if (!style.strokeDashArray.isEmpty()) {
                            style.specifiedFlags |= SPECIFIED_STROKE_DASHARRAY
                        }
                    case "stroke_dashoffset" =>
                        style.strokeDashOffset = SVGParserImpl.parseLength(val)
                        style.specifiedFlags |= SPECIFIED_STROKE_DASHOFFSET
                    case "opacity" =>
                        style.opacity = parseOpacity(val)
                        style.specifiedFlags |= SPECIFIED_OPACITY
                    case "color" =>
                        style.color = SVGParserImpl.parseColour(val)
                        style.specifiedFlags |= SPECIFIED_COLOR
                    case "font" => parseFont(style, val)
                    case "font_family" =>
                        style.fontFamily = SVGParserImpl.parseFontFamily(val)
                        if (!style.fontFamily.isEmpty()) {
                            style.specifiedFlags |= SPECIFIED_FONT_FAMILY
                        }

                    case "font_size" =>
                        style.fontSize = parseFontSize(val)
                        style.specifiedFlags |= SPECIFIED_FONT_SIZE
                    case "font_weight" =>
                        style.fontWeight = parseFontWeight(val)
                        if (style.fontWeight != 0.0) {
                            style.specifiedFlags |= SPECIFIED_FONT_WEIGHT
                        }
                    case "font_style" =>
                        style.fontStyle = parseFontStyle(val)
                        if (style.fontStyle.isSome()) {
                            style.specifiedFlags |= SPECIFIED_FONT_STYLE
                        }
                    case "text_decoration" =>
                        style.textDecoration = parseTextDecoration(val)
                        if (style.textDecoration != "") {
                            style.specifiedFlags |= SPECIFIED_TEXT_DECORATION
                        }
                    case "direction" =>
                        style.direction = parseTextDirection(val)
                        if (style.direction != "") {
                            style.specifiedFlags |= SPECIFIED_DIRECTION
                        }

                    case "text_anchor" =>
                        style.textAnchor = parseTextAnchor(val)
                        if (style.textAnchor != "") {
                            style.specifiedFlags |= SPECIFIED_TEXT_ANCHOR
                        }

                    case "overflow" =>
                        style.overflow = parseOverflow(val)
                        if (style.overflow != false) {
                            style.specifiedFlags |= SPECIFIED_OVERFLOW
                        }
                    case "marker" =>
                        style.markerStart = parseFunctionalIRI(val)
                        style.markerMid = style.markerStart
                        style.markerEnd = style.markerStart
                        style.specifiedFlags |= (SPECIFIED_MARKER_START | SPECIFIED_MARKER_MID | SPECIFIED_MARKER_END)

                    case "marker_start" =>
                        style.markerStart = parseFunctionalIRI(val)
                        style.specifiedFlags |= SPECIFIED_MARKER_START

                    case "marker_mid" =>
                        style.markerMid = parseFunctionalIRI(val)
                        style.specifiedFlags |= SPECIFIED_MARKER_MID

                    case "marker_end" =>
                        style.markerEnd = parseFunctionalIRI(val)
                        style.specifiedFlags |= SPECIFIED_MARKER_END

                    case "display" => if (val.indexOf('|').isNone() || SVGParserImpl.VALID_DISPLAY_VALUES.contains(
                        '|' + val + '|')) {
                        style.display = !(val == "")
                        style.specifiedFlags |= SPECIFIED_DISPLAY
                    }

                    case "visibility" => if (val.indexOf('|').isNone() ||
                        SVGParserImpl.VALID_VISIBILITY_VALUES.contains('|' + val + '|')) {
                        style.visibility = val == ("visible")
                        style.specifiedFlags |= SPECIFIED_VISIBILITY
                    }

                    case "stop_color" =>
                        if (val == SVGParserImpl.CURRENTCOLOR) {
                            style.stopColor = CurrentColor.getInstance()
                        } else {
                            try {
                                style.stopColor = SVGParserImpl.parseColour(val)
                            } catch (e: SVGParseException) {
                            }
                        }
                        style.specifiedFlags |= SPECIFIED_STOP_COLOR

                    case "stop_opacity" =>
                        style.stopOpacity = parseOpacity(val)
                        style.specifiedFlags |= SPECIFIED_STOP_OPACITY

                    case "clip" =>
                        style.clip = parseClip(val)
                        if (style.clip.isSome()) {
                            style.specifiedFlags |= SPECIFIED_CLIP
                        }

                    case "clip_path" =>
                        style.clipPath = parseFunctionalIRI(val)
                        style.specifiedFlags |= SPECIFIED_CLIP_PATH

                    case "clip_rule" =>
                        style.clipRule = parseFillRule(val)
                        style.specifiedFlags |= SPECIFIED_CLIP_RULE

                    case "mask" =>
                        style.mask = parseFunctionalIRI(val)
                        style.specifiedFlags |= SPECIFIED_MASK

                    case "solid_color" =>
                        if (val == SVGParserImpl.CURRENTCOLOR) {
                            style.solidColor = CurrentColor.getInstance()
                        } else {
                            try {
                                style.solidColor = SVGParserImpl.parseColour(val)
                            } catch (e: SVGParseException) {
                            }
                        }
                        style.specifiedFlags |= SPECIFIED_SOLID_COLOR

                    case "solid_opacity" =>
                        style.solidOpacity = parseOpacity(val)
                        style.specifiedFlags |= SPECIFIED_SOLID_OPACITY

                    case "viewport_fill" =>
                        if (val == SVGParserImpl.CURRENTCOLOR) {
                            style.viewportFill = CurrentColor.getInstance()
                        } else {
                            try {
                                style.viewportFill = SVGParserImpl.parseColour(val)
                            } catch (e: SVGParseException) {
                            }
                        }
                        style.specifiedFlags |= SPECIFIED_VIEWPORT_FILL

                    case "viewport_fill_opacity" =>
                        style.viewportFillOpacity = parseOpacity(val)
                        style.specifiedFlags |= SPECIFIED_VIEWPORT_FILL_OPACITY

                    case "vector_effect" =>
                        style.vectorEffect = parseVectorEffect(val)
                        if (style.vectorEffect != "") {
                            style.specifiedFlags |= SPECIFIED_VECTOR_EFFECT
                        }

                    case "image_rendering" =>
                        style.imageRendering = parseRenderQuality(val)
                        if (style.imageRendering != "") {
                            style.specifiedFlags |= SPECIFIED_IMAGE_RENDERING
                        }
                    case _ => ()
                }
            }
        }
    }

    static func parseFunctionalIRI(val: String): String {
        if (val == "none") {
            return ""
        }
        if (!val.startsWith("url(")) {
            return ""
        }
        if (val.endsWith(")")) {
            return val[4..val.size - 1].trimAscii()
        } else {
            return val[4..].trimAscii()
        }
    }

    // Parse a text anchor keyword
    private static func parseOverflow(val: String): Bool {
        match (val) {
            case "visible" => return true
            case "auto" => return true
            case "hidden" => return false
            case "scroll" => return false
            case _ => return false
        }
    }

    // Parse CSS clip shape (always a rect())
    private static func parseClip(val: String): ?CSSClipRect {
        if ("auto" == val) {
            return None
        }
        if (!val.startsWith("rect(")) {
            return None
        }
        let scan: TextScanner = TextScanner(val[5..])
        scan.skipWhitespace()
        let top: SVGLength = parseLengthOrAuto(scan)
        scan.skipCommaWhitespace()
        let right: SVGLength = parseLengthOrAuto(scan)
        scan.skipCommaWhitespace()
        let bottom: SVGLength = parseLengthOrAuto(scan)
        scan.skipCommaWhitespace()
        let left: SVGLength = parseLengthOrAuto(scan)
        scan.skipWhitespace()
        if (!scan.consume(')') && !scan.empty()) {
            // Be forgibing. Allow missing ')'.
            return None
        }
        return CSSClipRect(top, right, bottom, left)
    }

    private static func parseLengthOrAuto(scan: TextScanner): SVGLength {
        if (scan.consume("auto")) {
            return SVGLength(0.0)
        }
        return scan.nextLength() ?? SVGLength()
    }

    // Parse a vector effect keyword
    private static func parseVectorEffect(val: String): String {
        let ve: VectorEffect = VectorEffect()
        match (val) {
            case "none" => return ve.None
            case "non-scaling-stroke" => return ve.NonScalingStroke
            case _ => return ""
        }
    }

    // Parse a rendering quality property
    private static func parseRenderQuality(val: String): String {
        let rq: RenderQuality = RenderQuality()
        match (val) {
            case "auto" => return rq.auto
            case "optimizeQuality" => return rq.optimizeQuality
            case "optimizeSpeed" => return rq.optimizeSpeed
            case _ => return ""
        }
    }

    private static func parseTextAnchor(val: String): String {
        let ta: TextAnchor = TextAnchor()
        match (val) {
            case "start" => return ta.Start
            case "middle" => return ta.Middle
            case "end" => return ta.End
            case _ => return ""
        }
    }

    static func parseTextDecoration(val: String): String {
        let td: TextDecoration = TextDecoration()
        match (val) {
            case "none" => return td.None
            case "underline" => return td.Underline
            case "overline" => return td.Overline
            case "line-through" => return td.LineThrough
            case "blink" => return td.Blink
            case _ => return ""
        }
    }

    static func parseTextDirection(val: String): String {
        let td: TextDirection = TextDirection()
        match (val) {
            case "ltr" => return td.LTR
            case "rtl" => return td.RTL
            case _ => return ""
        }
    }

    static func parseFontWeight(val: String): Float64 {
        let fontWeightKeywords = FontWeightKeywords()
        var result: ?Float64 = fontWeightKeywords.getValue(val)
        if (result.isNone()) {
            let scan: TextScanner = TextScanner(val)
            result = scan.nextFloat()
            scan.skipWhitespace()
            if (!scan.empty()) {
                return 0.0
            }
            if (result() < Style.FONT_WEIGHT_MIN || result() > Style.FONT_WEIGHT_MAX) {
                return 0.0
            }
        }
        return result()
    }

    // Parse a font attribute
    // [ [ <'font-style'> || <'font-variant'> || <'font-weight'> ]? <'font-size'> [ / <'line-height'> ]? <'font-family'> ] | caption | icon | menu | message-box | small-caption | status-bar | inherit
    private static func parseFont(style: Style, val: String): Unit {
        var fontWeight: ?Float64 = None
        var fontStyle: ?FontStyle = None
        var fontVariant: String = ""
        // Start by checking for the fixed size standard system font names (which we don't support)
        if (!"|caption|icon|menu|message-box|small-caption|status-bar|".contains('|' + val + '|')) {
            return
        }
        // First part: style/variant/weight (opt - one or more)
        let scan: TextScanner = TextScanner(val)
        var item: String = ""
        while (true) {
            item = scan.nextToken(terminator: "/")
            scan.skipWhitespace()
            if (item == "") {
                return
            }
            if (fontWeight.isSome() && fontStyle.isSome()) {
                break
            }
            if (item == "normal") {
                // indeterminate which of these this refers to
                continue
            }
            if (fontWeight.isNone()) {
                fontWeight = FontWeightKeywords().getValue(item)
                if (fontWeight.isSome()) {
                    continue
                }
            }
            if (fontStyle.isNone()) {
                fontStyle = parseFontStyle(item)
                if (fontStyle.isSome()) {
                    continue
                }
            }
            // Must be a font-variant keyword?
            if (fontVariant == "" && item == "small-caps") {
                fontVariant = item
                continue
            }
            // Not any of these. Break and try next section
            break
        }

        // Second part: font size (reqd) and line-height (opt)
        let fontSize: SVGLength = parseFontSize(item)

        // Check for line-height (which we don't support)
        if (scan.consume('/')) {
            scan.skipWhitespace()
            item = scan.nextToken()
            if (item != "") {
                try {
                    SVGParserImpl.parseLength(item)
                } catch (e: SVGParseException) {
                    return
                }
            }
            scan.skipWhitespace()
        }
        // Third part: font family
        style.fontFamily = SVGParserImpl.parseFontFamily(scan.restOfText())
        style.fontSize = fontSize
        style.fontWeight = if (let Some(v) <- fontWeight) {
            v
        } else {
            Style.FONT_WEIGHT_NORMAL
        }
        style.fontStyle = if (let Some(v) <- fontStyle) {
            v
        } else {
            FontStyle.Normal
        }
        style.specifiedFlags |= (SPECIFIED_FONT_FAMILY | SPECIFIED_FONT_SIZE | SPECIFIED_FONT_WEIGHT |
            SPECIFIED_FONT_STYLE)
    }

    static func parseFontSize(val: String): SVGLength {
        try {
            let fontSizeKeywords: FontSizeKeywords = FontSizeKeywords()
            var sizes: ?SVGLength = fontSizeKeywords.get(val)
            if (sizes.isNone()) {
                sizes = SVGParserImpl.parseLength(val)
            }
            return sizes()
        } catch (e: Exception) {
            return SVGLength()
        }
    }

    static func parseFontStyle(val: String): ?FontStyle {
        match (val) {
            case "italic" => return FontStyle.Italic
            case "normal" => return FontStyle.Normal
            case _ => return None
        }
    }

    private static func parseOpacity(val: String): Float64 {
        let o: Float64 = SVGParserImpl.parseFloat(val)
        return if (o < 0.0) {
            0.0
        } else {
            if (o > 1.0) {
                1.0
            } else {
                o
            }
        }
    }

    private static func parseStrokeLineCap(val: String): ?LineCap {
        if ("butt" == val) {
            return LineCap.Butt
        }
        if ("round" == val) {
            return LineCap.Round
        }
        if ("square" == val) {
            return LineCap.Square
        }
        return None
    }

    // Parse stroke-linejoin
    private static func parseStrokeLineJoin(val: String): ?LineJoin {
        if ("miter" == val) {
            return LineJoin.Miter
        }
        if ("round" == val) {
            return LineJoin.Round
        }
        if ("bevel" == val) {
            return LineJoin.Bevel
        }
        return None
    }

    private static func parseStrokeDashArray(val: String): ArrayList<SVGLength> {
        let EMPTY_ARRAYLIST: ArrayList<SVGLength> = ArrayList<SVGLength>()
        let scan: TextScanner = TextScanner(val)
        scan.skipWhitespace()
        if (scan.empty()) {
            return EMPTY_ARRAYLIST
        }
        var dash = scan.nextLength()
        if (dash.isNone()) {
            return EMPTY_ARRAYLIST
        }
        var dashValue = dash()
        if (dashValue.isNegative()) {
            return EMPTY_ARRAYLIST
        }
        var sum: Float64 = dashValue.getFloatValue()
        let dashes: ArrayList<SVGLength> = ArrayList<SVGLength>()
        dashes.append(dashValue)
        while (!scan.empty()) {
            scan.skipCommaWhitespace()
            dash = scan.nextLength()
            if (dash.isNone()) {
                // must have hit something unexpected
                return EMPTY_ARRAYLIST
            }
            dashValue = dash()
            if (dashValue.isNegative()) {
                return EMPTY_ARRAYLIST
            }
            dashes.append(dashValue)
            sum += dashValue.getFloatValue()
        }
        // Spec (section 11.4) says if the sum of dash lengths is zero, it should
        // be treated as "none" ie a solid stroke.
        if (sum == 0.0) {
            return EMPTY_ARRAYLIST
        }
        return dashes
    }

    static func parsePaintSpecifier(v: String): SvgPaint {
        var val: String = v
        if (val.startsWith("url(")) {
            let closeBracket: ?Int64 = val.indexOf(")")
            var href: String
            if (let Some(v) <- closeBracket) {
                href = val[4..v].trimAscii()
                var fallback: ?SvgPaint = None
                val = val[(v + 1)..].trimAscii()
                if (val.size > 0) {
                    fallback = parseColourSpecifer(val)
                }
                return PaintReference(href, fallback)
            } else {
                href = val[4..].trimAscii()
                return PaintReference(href, Option<SvgPaint>.None)
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
                return SVGParserImpl.parseColour(val)
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
    let LTR: String = "LTR"
    let RTL: String = "RTL"
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

class FontSizeKeywords {
    private let fontSizeKeywords: HashMap<String, SVGLength> = HashMap<String, SVGLength>()

    init() {
        this.fontSizeKeywords.put("xx-small", SVGLength(0.694, u: Units.pt))
        this.fontSizeKeywords.put("x-small", SVGLength(0.833, u: Units.pt))
        this.fontSizeKeywords.put("small", SVGLength(10.0, u: Units.pt))
        this.fontSizeKeywords.put("medium", SVGLength(12.0, u: Units.pt))
        this.fontSizeKeywords.put("large", SVGLength(14.4, u: Units.pt))
        this.fontSizeKeywords.put("x-large", SVGLength(17.3, u: Units.pt))
        this.fontSizeKeywords.put("xx-large", SVGLength(20.7, u: Units.pt))
        this.fontSizeKeywords.put("smaller", SVGLength(83.33, u: Units.percent))
        this.fontSizeKeywords.put("larger", SVGLength(120.0, u: Units.percent))
    }

    func get(fontSize: String): ?SVGLength {
        return this.fontSizeKeywords.get(fontSize)
    }
}

class FontWeightKeywords {
    private let fontWeightKeywords: HashMap<String, Float64> = HashMap<String, Float64>()

    init() {
        this.fontWeightKeywords.put("normal", Style.FONT_WEIGHT_NORMAL)
        this.fontWeightKeywords.put("bold", Style.FONT_WEIGHT_BOLD)
        this.fontWeightKeywords.put("bolder", Style.FONT_WEIGHT_BOLDER)
        this.fontWeightKeywords.put("lighter", Style.FONT_WEIGHT_LIGHTER)
    }

    func getValue(fontWeight: String): ?Float64 {
        return this.fontWeightKeywords.get(fontWeight)
    }

    func contains(fontStretch: String): Bool {
        return this.fontWeightKeywords.contains(fontStretch)
    }
}

class FontStretchKeywords {
    private let fontStretchKeywords: HashMap<String, Float64> = HashMap<String, Float64>()

    init() {
        this.fontStretchKeywords.put("ultra-condensed", 50.0)
        this.fontStretchKeywords.put("extra-condensed", 62.5)
        this.fontStretchKeywords.put("condensed", 75.0)
        this.fontStretchKeywords.put("semi-condensed", 87.5)
        this.fontStretchKeywords.put("normal", Style.FONT_STRETCH_NORMAL)
        this.fontStretchKeywords.put("semi-expanded", 112.5)
        this.fontStretchKeywords.put("expanded", 125.0)
        this.fontStretchKeywords.put("extra-expanded", 150.0)
        this.fontStretchKeywords.put("ultra-expanded", 200.0)
    }

    func getValue(fontStretch: String): ?Float64 {
        return this.fontStretchKeywords.get(fontStretch)
    }

    func contains(fontStretch: String): Bool {
        return this.fontStretchKeywords.contains(fontStretch)
    }
}
