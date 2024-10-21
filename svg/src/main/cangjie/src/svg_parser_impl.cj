/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class SVGParserImpl <: SVGParser {
    private static let FEATURE_STRING_PREFIX: String = "http://www.w3.org/TR/SVG11/feature#"
    private static let PATTERN_BLOCK_COMMENTS: Regex = Regex("/\\/\\*[\\s\\S]*?\\*\\//")
    public static let XML_STYLESHEET_ATTR_TYPE: String = "type"
    public static let XML_STYLESHEET_ATTR_ALTERNATE: String = "alternate"
    public static let XML_STYLESHEET_ATTR_HREF: String = "href"
    public static let XML_STYLESHEET_ATTR_MEDIA: String = "media"
    public static let XML_STYLESHEET_ATTR_MEDIA_ALL: String = "all"
    public static let XML_STYLESHEET_ATTR_ALTERNATE_NO: String = "no"
    public static let ENTITY_WATCH_BUFFER_SIZE: Int64 = 4096
    static let NONE: String = "none"
    static let CURRENTCOLOR: String = "currentColor"
    static let VALID_DISPLAY_VALUES: String = "|inline|block|list-item|run-in|compact|marker|table|inline-table" +
        "|table-row-group|table-header-group|table-footer-group|table-row" +
        "|table-column-group|table-column|table-cell|table-caption|none|"
    static let VALID_VISIBILITY_VALUES: String = "|visible|hidden|collapse|"
    var svgDocument: ?SVGBase = None
    private var currentElement: ?SvgContainer = None
    private var ignoring: Bool = false
    private var ignoreDepth: Int64 = 0
    var enableInternalEntities: Bool = true
    var externalFileResolver: SVGExternalFileResolver = SVGExternalFileResolver()
    private var metadataTag: String = ""
    private var metadataElementContents: String = ""
    private var styleElementContents: String = ""
    private var inMetadataElement: Bool = false

    public func parseString(s: String): SVGBase {
        var str = s
        str = str.replace("stroke-", "stroke_").replace("font-", "font_").replace("text-", "text").replace("fill-",
            "fill_").replace("stop-", "stop_").replace("clip-", "clip_").replace("marker-", "marker_").replace("xml:",
            "xml_")
        startDocument()
        let buf = ByteArrayStream()
        buf.write(str.toArray())
        let parser: StaxXmlPullParser = StaxXmlPullParser(buf)
        while (parser.getEventType() != XmlPullParserEvent.END_DOCUMENT) {
            let event = parser.next()
            match (event) {
                case START_ELEMENT => startElement(parser)
                case END_ELEMENT => endElement(parser.getName())
                case OTHER => ()
                case _ => ()
            }
        }
        return this.svgDocument()
    }

    public func setInternalEntitiesEnabled(enable: Bool): SVGParser {
        this.enableInternalEntities = enable
        return this
    }

    public func setExternalFileResolver(fileResolver: SVGExternalFileResolver): SVGParser {
        this.externalFileResolver = fileResolver
        return this
    }

    func text(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Text2 = Text2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesTextPosition(obj, data)
        parseElementsOfText(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseElementsOfText(svg: Text2, data: StaxXmlPullParser): Unit {
        if (data.getAttributeCount() <= 0) {
            return
        }
        for (i in 0..data.getAttributeCount()) {
            match (data.getAttributeName(i)) {
                case "text" => svg.text = data.getAttributeValue(i)
                case _ => ()
            }
        }
    }

    private func parseElementsOfTSpan(svg: TSpan, data: StaxXmlPullParser): Unit {
        if (data.getAttributeCount() <= 0) {
            return
        }
        for (i in 0..data.getAttributeCount()) {
            match (data.getAttributeName(i)) {
                case "text" => svg.text = data.getAttributeValue(i)
                case _ => ()
            }
        }
    }

    private func parseAttributesCore(obj: SvgElementBase, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let qname: String = data.getAttributeName(i)
            if (qname == "id" || qname == "xml:id") {
                obj.id = data.getAttributeValue(i).trimAscii()
                break
            }
            if (qname == "xml:space") {
                let val: String = data.getAttributeValue(i).trimAscii()
                if ("default" == val) {
                    obj.spacePreserve = false
                } else {
                    if ("preserve" != val) {
                        throw SVGParseException("Invalid value for \"xml:space\" attribute: " + val)
                    }
                    obj.spacePreserve = true
                }
                break
            }
        }
    }

    private func parseAttributesStyle(obj: SvgElementBase, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i).trimAscii()
            if (val.size == 0) {
                continue
            }
            match (data.getAttributeName(i)) {
                case "style" => parseStyle(obj, val)
                case "class" => obj.classNames = CSSParser.parseClassAttribute(val)
                case _ => Style.processStyleProperty(obj.baseStyle, data.getAttributeName(i),
                    data.getAttributeValue(i).trimAscii())
            }
        }
    }

    private func parseAttributesTransform(obj: HasTransform, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            if (data.getAttributeName(i) == "transform") {
                obj.setTransform(parseTransformList(data.getAttributeValue(i)))
            }
        }
    }

    private func parseTransformList(val: String): Matrix2D2 {
        let matrix: Matrix2D2 = Matrix2D2()
        let scan: TextScanner = TextScanner(val)
        scan.skipWhitespace()
        while (!scan.empty()) {
            let cmd: String = scan.nextFunction()

            if (cmd == "") {
                return matrix
            }
            match (cmd) {
                case "matrix" =>
                    scan.skipWhitespace()
                    let a = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    let b = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    let c = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    let d = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    let e = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    let f = scan.nextFloat()
                    scan.skipWhitespace()
                    if (f.isNaN() || !scan.consume(")")) {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                    let m: Matrix2D2 = Matrix2D2()
                    m.setValues(a: a, b: c, c: e, d: b, tx: d / pxTovp, ty: f / pxTovp)
                    matrix.appendMatrix(m)
                case "translate" =>
                    scan.skipWhitespace()
                    let tx: Float64 = scan.nextFloat()
                    let ty: Float64 = scan.possibleNextFloat()
                    scan.skipWhitespace()
                    if (tx.isNaN() || !scan.consume(")")) {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                    if (ty.isNaN()) {
                        matrix.translate(tx / pxTovp, y: 0.0)
                    } else {
                        matrix.translate(tx / pxTovp, y: ty / pxTovp)
                    }
                case "scale" =>
                    scan.skipWhitespace()
                    let sx: Float64 = scan.nextFloat()
                    let sy: Float64 = scan.possibleNextFloat()
                    scan.skipWhitespace()
                    if (sx.isNaN() || !scan.consume(")")) {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                    if (sy.isNaN()) {
                        matrix.scale(sx, y: sx)
                    } else {
                        matrix.scale(sx, y: sy)
                    }
                case "rotate" =>
                    scan.skipWhitespace()
                    let ang: Float64 = scan.nextFloat()
                    let cx: Float64 = scan.possibleNextFloat()
                    let cy: Float64 = scan.possibleNextFloat()
                    scan.skipWhitespace()
                    if (ang.isNaN() || !scan.consume(")")) {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                    if (cx.isNaN()) {
                        matrix.rotate(ang)
                    } else if (!cy.isNaN()) {
                        matrix.rotate(ang, cx: cx, cy: cy)
                    } else {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                case "skewX" =>
                    scan.skipWhitespace()
                    let ang: Float64 = scan.nextFloat()
                    scan.skipWhitespace()
                    if (ang.isNaN() || !scan.consume(")")) {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                    matrix.skew(tan(ang * (Float64.PI / 180.0)), 0.0)
                case "skewY" =>
                    scan.skipWhitespace()
                    let ang2: Float64 = scan.nextFloat()
                    scan.skipWhitespace()
                    if (ang2.isNaN() || !scan.consume(")")) {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                    matrix.skew(0.0, tan(ang2 * (Float64.PI / 180.0)))
                case _ => throw SVGParseException("Invalid transform list fn: " + cmd + ")")
            }
            if (scan.empty()) {
                break
            }
            scan.skipCommaWhitespace()
        }
        return matrix
    }

    private static func parseStyle(obj: SvgElementBase, style: String): Unit {
        let scan: CSSTextScanner = CSSTextScanner(SVGParserImpl.PATTERN_BLOCK_COMMENTS.matcher(style).replaceAll(""))
        while (!scan.empty()) {
            scan.skipWhitespace()
            let propertyName: String = scan.nextIdentifier()

            scan.skipWhitespace()
            if (scan.consume(";")) {
                continue
            }
            if (!scan.consume(":")) {
                break
            }
            scan.skipWhitespace()
            let propertyValue: String = scan.nextPropertyValue()
            if (propertyValue == "") {
                continue
            }
            scan.skipWhitespace()
            if (scan.empty() || scan.consume(";")) {
                if (let Some(v) <- obj.style) {
                    Style.processStyleProperty(v, propertyName, propertyValue)
                } else {
                    obj.style = Style()
                    Style.processStyleProperty(obj.style(), propertyName, propertyValue)
                }
                scan.skipWhitespace()
            }
        }
    }

    func startDocument(): Unit {
        this.svgDocument = SVGBase(this.enableInternalEntities, this.externalFileResolver)
    }

    private func svg(data: StaxXmlPullParser): Unit {
        let obj: Svg = Svg()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesSVG(obj, data)
        parseAttributesViewBox(obj, data)
        if (let Some(v) <- this.currentElement) {
            v.addChild(obj)
        } else {
            this.svgDocument().setRootElement(obj)
        }
        this.currentElement = obj
    }

    private func g(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Group = Group()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func defs(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Defs = Defs()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func a(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: A = A()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesA(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesA(obj: A, data: StaxXmlPullParser) {
        for (i in 0..data.getAttributeCount()) {
            match (data.getAttributeName(i)) {
                case "href" => obj.href = data.getAttributeValue(i)
                case _ => ()
            }
        }
    }

    private func use(data: StaxXmlPullParser) {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Use = Use()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesUse(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesUse(obj: Use, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "x" => obj.x = parseLength(val)
                case "y" => obj.y = parseLength(val)
                case "width" =>
                    obj.width = parseLength(val)
                    if (obj.width.isNegative()) {
                        throw SVGParseException("Invalid <use> element. width cannot be negative")
                    }
                case "height" =>
                    obj.height = parseLength(val)
                    if (obj.height.isNegative()) {
                        throw SVGParseException("Invalid <use> element. height cannot be negative")
                    }
                case "href" => obj.href = val
                case _ => ()
            }
        }
    }

    private func parseAttributesViewBox(obj: SvgViewBoxContainer, data: StaxXmlPullParser): Unit {
        var isViewBox = false
        for (i in 0..data.getAttributeCount()) {
            let content: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "viewBox" =>
                    isViewBox = true
                    obj.viewBox = parseViewBox(content)
                case "preserveAspectRatio" => parsePreserveAspectRatio(obj, content)
                case _ => ()
            }
        }
        if (!isViewBox) {
            if (let Some(s) <- obj as Svg) {
                let svg: Svg = s
                if (svg.width.uni == "" || svg.width.uni == Units.percent) {
                    throw SVGParseException("Invalid width definition - must not percent when no viewbox")
                }
                if (svg.height.uni == "" || svg.height.uni == Units.percent) {
                    throw SVGParseException("Invalid height definition - must not percent when no viewbox")
                }
                svg.viewBox = Box(0.0, 0.0, svg.width.value, svg.height.value)
            }
        }
    }

    private static func parseViewBox(content: String): Box {
        let scan: TextScanner = TextScanner(content)
        scan.skipWhitespace()
        let minX: Float64 = scan.nextFloat()
        scan.skipCommaWhitespace()
        let minY: Float64 = scan.nextFloat()
        scan.skipCommaWhitespace()
        let width: Float64 = scan.nextFloat()
        scan.skipCommaWhitespace()
        let height: Float64 = scan.nextFloat()
        if (minX.isNaN() || minY.isNaN() || width.isNaN() || height.isNaN()) {
            throw SVGParseException("Invalid viewBox definition - should have four numbers")
        }
        if (width < 0.0) {
            throw SVGParseException("Invalid viewBox. width cannot be negative")
        }
        if (height < 0.0) {
            throw SVGParseException("Invalid viewBox. height cannot be negative")
        }
        return Box(minX, minY, width, height)
    }

    private static func parsePreserveAspectRatio(obj: SvgPreserveAspectRatioContainer, content: String): Unit {
        obj.preserveAspectRatio = PreserveAspectRatio.of(content)
    }

    private func parseAttributesSVG(obj: Svg, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let content: String = data.getAttributeValue(i).trimAscii()
            match (data.getAttributeName(i)) {
                case "x" => obj.x = parseLength(content)
                case "y" => obj.y = parseLength(content)
                case "width" =>
                    obj.width = parseLength(content)
                    if (obj.width.isNegative()) {
                        throw SVGParseException("Invalid <svg> element. width cannot be negative")
                    }
                case "height" =>
                    obj.height = parseLength(content)
                    if (obj.height.isNegative()) {
                        throw SVGParseException("Invalid <svg> element. height cannot be negative")
                    }
                case "version" => obj.version = content
                case _ => ()
            }
        }
    }

    static func parseLength(val: String): SVGLength {
        if (val.size == 0) {
            throw SVGParseException("Invalid length value (empty string)")
        }
        var end: Int64 = val.size
        var unit: String = Units.px
        let lastChar: Byte = val[end - 1]
        if (lastChar == b'%') {
            end -= 1
            unit = Units.percent
        } else if (end > 2 && lastChar.isAsciiLetter() && val[end - 2].isAsciiLetter()) {
            end -= 2
            let unitStr: String = val[end..]
            try {
                unit = unitStr.toAsciiLower()
            } catch (e: SVGParseException) {
                throw SVGParseException("Invalid length unit specifier: " + val)
            }
        }
        try {
            let scalar: Float64 = parseFloat(val)
            return SVGLength(scalar, u: unit)
        } catch (e: SVGParseException) {
            throw SVGParseException("Invalid length value: " + val)
        }
    }

    static func parseFloat(val: String, o!: Int64 = 0, l!: Int64 = val.size): Float64 {
        let np: NumberParser = NumberParser()
        let num: Float64 = np.parseNumber(val, o, l)
        if (!num.isNaN()) {
            return num
        } else {
            throw SVGParseException("Invalid number value: " + val)
        }
    }

    private func parseAttributesConditional(obj: SvgConditional, data: StaxXmlPullParser) {
        if (data.getAttributeCount() <= 0) {
            return
        }
        for (i in 0..data.getAttributeCount()) {
            match (data.getAttributeName(i)) {
                case "requiredFeatures" => obj.setRequiredFeatures(parseRequiredFeatures(data.getAttributeValue(i)))
                case "requiredExtensions" => obj.setRequiredExtensions(data.getAttributeValue(i))
                case "systemLanguage" => obj.setSystemLanguage(parseSystemLanguage(data.getAttributeValue(i)))
                case "requiredFormats" => obj.setRequiredFormats(parseRequiredFormats(data.getAttributeValue(i)))
                case "requiredFonts" =>
                    let fonts: ArrayList<String> = parseFontFamily(data.getAttributeValue(i))
                    var fontSet: HashSet<String> = if (fonts.size > 0) {
                        HashSet<String>(fonts)
                    } else {
                        HashSet<String>()
                    }
                    obj.setRequiredFonts(fontSet)
                case _ => ()
            }
        }
    }

    private static func parseRequiredFeatures(content: String): HashSet<String> {
        let scan: TextScanner = TextScanner(content)
        var result: HashSet<String> = HashSet<String>()
        while (!scan.empty()) {
            let feature: String = scan.nextToken()
            if (feature.startsWith(SVGParserImpl.FEATURE_STRING_PREFIX)) {
                result.put(feature[SVGParserImpl.FEATURE_STRING_PREFIX.size..])
            } else {
                result.put("UNSUPPORTED")
            }
            scan.skipWhitespace()
        }
        return result
    }

    private static func parseSystemLanguage(content: String): HashSet<String> {
        let scan: TextScanner = TextScanner(content)
        var result: HashSet<String> = HashSet<String>()
        while (!scan.empty()) {
            var language = scan.nextToken()
            let hyphenPos = language.indexOf('-')
            if (let Some(v) <- hyphenPos) {
                language = language[..v]
            }
            //            language = content TODO..
            result.put(language)
            scan.skipWhitespace()
        }
        return result
    }

    private static func parseRequiredFormats(content: String): HashSet<String> {
        let scan: TextScanner = TextScanner(content)
        var result: HashSet<String> = HashSet<String>()
        while (!scan.empty()) {
            let mimetype: String = scan.nextToken()
            result.put(mimetype)
            scan.skipWhitespace()
        }
        return result
    }

    static func parseFontFamily(content: String): ArrayList<String> {
        var fonts: ArrayList<String> = ArrayList<String>()
        let scan: TextScanner = TextScanner(content)
        while (true) {
            var item: String = scan.nextQuotedString()
            if (item == "") {
                item = scan.nextTokenWithWhitespace(',')
            }
            if (item == "") {
                break
            }
            if (fonts.isEmpty()) {
                fonts = ArrayList<String>()
            }
            fonts.append(item)
            scan.skipCommaWhitespace()
            if (scan.empty()) {
                break
            }
        }
        return fonts
    }

    func startElement(data: StaxXmlPullParser): Unit {
        let name: String = data.getName()
        if (this.ignoring) {
            this.ignoreDepth++
        }
        if (name == SVGXMLConstants.SVG_SVG_TAG) {
            svg(data)
        } else if (name == SVGXMLConstants.SVG_G_TAG) {
            g(data)
        } else if (name == SVGXMLConstants.SVG_DEFS_TAG) {
            defs(data)
        } else if (name == SVGXMLConstants.SVG_A_TAG) {
            a(data)
        } else if (name == SVGXMLConstants.SVG_USE_TAG) {
            use(data)
        } else if (name == SVGXMLConstants.SVG_PATH_TAG) {
            path(data)
        } else if (name == SVGXMLConstants.SVG_RECT_TAG) {
            rect(data)
        } else if (name == SVGXMLConstants.SVG_CIRCLE_TAG) {
            circle(data)
        } else if (name == SVGXMLConstants.SVG_ELLIPSE_TAG) {
            ellipse(data)
        } else if (name == SVGXMLConstants.SVG_LINE_TAG) {
            line(data)
        } else if (name == SVGXMLConstants.SVG_POLYLINE_TAG) {
            polyline(data)
        } else if (name == SVGXMLConstants.SVG_POLYGON_TAG) {
            polygon(data)
        } else if (name == SVGXMLConstants.SVG_TEXT_TAG) {
            text(data)
        } else if (name == SVGXMLConstants.SVG_TSPAN_TAG) {
            tspan(data)
        } else if (name == SVGXMLConstants.SVG_TREF_TAG) {
            tref(data)
        } else if (name == SVGXMLConstants.SVG_SWITCH_TAG) {
            zwitch(data)
        } else if (name == SVGXMLConstants.SVG_SYMBOL_TAG) {
            symbol(data)
        } else if (name == SVGXMLConstants.SVG_MARKER_TAG) {
            marker(data)
        } else if (name == SVGXMLConstants.SVG_LINEAR_GRADIENT_TAG) {
            linearGradient(data)
        } else if (name == SVGXMLConstants.SVG_RADIAL_GRADIENT_TAG) {
            radialGradient(data)
        } else if (name == SVGXMLConstants.SVG_STOP_TAG) {
            stop(data)
        } else if (name == SVGXMLConstants.SVG_TITLE_TAG) {
        } else if (name == SVGXMLConstants.SVG_DESC_TAG) {
            this.inMetadataElement = true
            this.metadataTag = name
        } else if (name == SVGXMLConstants.SVG_CLIP_PATH_TAG) {
            clipPath(data)
        } else if (name == SVGXMLConstants.SVG_TEXT_PATH_TAG) {
            textPath(data)
        } else if (name == SVGXMLConstants.SVG_PATTERN_TAG) {
            pattern(data)
        } else if (name == SVGXMLConstants.SVG_IMAGE_TAG) {
            image(data)
        } else if (name == SVGXMLConstants.SVG_VIEW_TAG) {
            view(data)
        } else if (name == SVGXMLConstants.SVG_MASK_TAG) {
            mask(data)
        } else if (name == SVGXMLConstants.SVG_STYLE_TAG) {
            style(data)
        } else {
            this.ignoring = true
            this.ignoreDepth = 1
        }
    }

    private func image(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Image2 = Image2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesImage(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesImage(obj: Image2, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "x" => obj.x = parseLength(val)
                case "y" => obj.y = parseLength(val)
                case "width" =>
                    obj.width = parseLength(val)
                    if (obj.width.isNegative()) {
                        throw SVGParseException("Invalid <use> element. width cannot be negative")
                    }
                case "height" =>
                    obj.height = parseLength(val)
                    if (obj.height.isNegative()) {
                        throw SVGParseException("Invalid <use> element. height cannot be negative")
                    }
                case "href" => obj.href = val
                case "preserveAspectRatio" => SVGParserImpl.parsePreserveAspectRatio(obj, val)
                case _ => ()
            }
        }
    }

    private func style(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        var isTextCSS: Bool = true
        var media: String = "all"
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "type" => isTextCSS = "text/css" == val
                case "media" => media = val
                case _ => ()
            }
        }
    }

    private func symbol(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Symbol = Symbol()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        this.parseAttributesCore(obj, data)
        this.parseAttributesStyle(obj, data)
        this.parseAttributesConditional(obj, data)
        this.parseAttributesViewBox(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func marker(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Marker = Marker()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesViewBox(obj, data)
        parseAttributesMarker(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesMarker(obj: Marker, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "refX" => obj.refX = parseLength(val)
                case "refY" => obj.refY = parseLength(val)
                case "markerWidth" =>
                    obj.markerWidth = parseLength(val)
                    if (obj.markerWidth.isNegative()) {
                        throw SVGParseException("Invalid <marker> element. markerWidth cannot be negative")
                    }
                case "markerHeight" =>
                    obj.markerHeight = parseLength(val)
                    if (obj.markerHeight.isNegative()) {
                        throw SVGParseException("Invalid <marker> element. markerHeight cannot be negative")
                    }
                case "markerUnits" => if ("strokeWidth" == val) {
                    obj.markerUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.markerUnitsAreUser = true
                } else {
                    throw SVGParseException("Invalid value for attribute markerUnits")
                }
                case "orient" => if ("auto" == val) {
                    obj.orient = Float64.NaN
                } else {
                    obj.orient = parseFloat(val)
                }

                case _ => ()
            }
        }
    }

    private func linearGradient(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: SvgLinearGradient = SvgLinearGradient()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesGradient(obj, data)
        parseAttributesLinearGradient(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesGradient(obj: GradientElement, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "gradientUnits" => if ("objectBoundingBox" == val) {
                    obj.gradientUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.gradientUnitsAreUser = true
                } else {
                    throw SVGParseException("Invalid value for attribute gradientUnits")
                }
                case "gradientTransform" => obj.gradientTransform = parseTransformList(val)
                case "spreadMethod" =>
                    try {
                        obj.spreadMethod.val = val
                    } catch (e: SVGParseException) {
                        throw SVGParseException("Invalid spreadMethod attribute. \"" + val + "\" is not a valid value.")
                    }
                    break
                case "href" => obj.href = val
                case _ => ()
            }
        }
    }

    private func parseAttributesLinearGradient(obj: SvgLinearGradient, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "x1" => obj.x1 = parseLength(val)
                case "y1" => obj.y1 = parseLength(val)
                case "x2" => obj.x2 = parseLength(val)
                case "y2" => obj.y2 = parseLength(val)
                case _ => ()
            }
        }
    }

    private func radialGradient(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: SvgRadialGradient = SvgRadialGradient()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesGradient(obj, data)
        parseAttributesRadialGradient(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesRadialGradient(obj: SvgRadialGradient, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "cx" => obj.cx = parseLength(val)
                case "cy" => obj.cy = parseLength(val)
                case "r" =>
                    obj.r = parseLength(val)
                    if (obj.r.isNegative()) {
                        throw SVGParseException("Invalid <radialGradient> element. r cannot be negative")
                    }
                case "fx" => obj.fx = parseLength(val)
                case "fy" => obj.fy = parseLength(val)
                case _ => ()
            }
        }
    }

    private func stop(data: StaxXmlPullParser): Unit {
        let current: SvgContainer = this.currentElement ?? throw SVGParseException(
            "Invalid document. Root element must be <svg>")
        if (!(current is GradientElement)) {
            throw SVGParseException(
                "Invalid document. <stop> elements are only valid inside <linearGradient> or <radialGradient> elements."
            )
        }
        let obj: Stop = Stop()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesStop(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesStop(obj: Stop, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "offset" => obj.offset = Int64(parseGradientOffset(val))
                case _ => ()
            }
        }
    }

    private func parseGradientOffset(val: String): Float64 {
        if (val.size == 0) {
            throw SVGParseException("Invalid offset value in <stop> (empty string)")
        }
        var end: Int64 = val.size
        var isPercent: Bool = false
        if (val[val.size - 1] == b'%') {
            end -= 1
            isPercent = true
        }
        try {
            var scalar: Float64 = parseFloat(val)
            if (isPercent) {
                scalar /= 100.0
            }
            if (scalar < 0.0) {
                return 0.0
            } else {
                if (scalar > 100.0) {
                    return 100.0
                }
                return scalar
            }
        } catch (e: SVGParseException) {
            throw SVGParseException("Invalid offset value in <stop>: " + val)
        }
    }

    private func clipPath(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: ClipPath = ClipPath()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesClipPath(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesClipPath(obj: ClipPath, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "clipPathUnits" => if ("objectBoundingBox" == val) {
                    obj.clipPathUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.clipPathUnitsAreUser = true
                } else {
                    throw SVGParseException("Invalid value for attribute clipPathUnits")
                }
                case _ => ()
            }
        }
    }

    private func textPath(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: TextPath = TextPath()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesTextPath(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesTextPath(obj: TextPath, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "href" => obj.href = val
                case "startOffset" => obj.startOffset = parseLength(val)
                case _ => ()
            }
        }
    }

    private func pattern(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Pattern = Pattern()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesViewBox(obj, data)
        parseAttributesPattern(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesPattern(obj: Pattern, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "patternUnits" => if ("objectBoundingBox" == val) {
                    obj.patternUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.patternUnitsAreUser = true
                } else {
                    throw SVGParseException("Invalid value for attribute patternUnits")
                }
                case "patternContentUnits" =>
                    if ("objectBoundingBox" == val) {
                        obj.patternContentUnitsAreUser = false
                    } else if ("userSpaceOnUse" == val) {
                        obj.patternContentUnitsAreUser = true
                    } else {
                        throw SVGParseException("Invalid value for attribute patternContentUnits")
                    }
                    break
                case "patternTransform" => obj.patternTransform = parseTransformList(val)
                case "x" => obj.x = parseLength(val)
                case "y" => obj.y = parseLength(val)
                case "width" =>
                    obj.width = parseLength(val)
                    if (obj.width.isNegative()) {
                        throw SVGParseException("Invalid <pattern> element. width cannot be negative")
                    }
                case "height" =>
                    obj.height = SVGParserImpl.parseLength(val)
                    if (obj.height.isNegative()) {
                        throw SVGParseException("Invalid <pattern> element. height cannot be negative")
                    }
                case "href" => obj.href = val

                case _ => ()
            }
        }
    }

    private func view(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: View = View()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesViewBox(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func mask(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Mask = Mask()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        this.parseAttributesCore(obj, data)
        this.parseAttributesStyle(obj, data)
        this.parseAttributesConditional(obj, data)
        this.parseAttributesMask(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func parseAttributesMask(obj: Mask, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "maskUnits" => if ("objectBoundingBox" == val) {
                    obj.maskUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.maskUnitsAreUser = true
                } else {
                    throw SVGParseException("Invalid value for attribute maskUnits")
                }
                case "maskContentUnits" => if ("objectBoundingBox" == val) {
                    obj.maskContentUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.maskContentUnitsAreUser = true
                } else {
                    throw SVGParseException("Invalid value for attribute maskContentUnits")
                }
                case "x" =>
                    obj.x = parseLength(val)
                    break
                case "y" =>
                    obj.y = parseLength(val)
                    break
                case "width" =>
                    obj.width = parseLength(val)
                    if (obj.width.isNegative()) {
                        throw SVGParseException("Invalid <mask> element. width cannot be negative")
                    }
                case "height" =>
                    obj.height = SVGParserImpl.parseLength(val)
                    if (obj.height.isNegative()) {
                        throw SVGParseException("Invalid <mask> element. height cannot be negative")
                    }
                case _ => ()
            }
        }
    }

    private func tspan(data: StaxXmlPullParser): Unit {
        let current = this.currentElement ?? throw SVGParseException("Invalid document. Root element must be <svg>")
        if (!(current is TextContainer)) {
            throw SVGParseException(
                "Invalid document. <tspan> elements are only valid inside <text> or other <tspan> elements.")
        }
        let obj: TSpan = TSpan()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesTextPosition(obj, data)
        currentElement().addChild(obj)
        parseElementsOfTSpan(obj, data)
        currentElement = obj
    }

    private func tref(data: StaxXmlPullParser): Unit {
        let current = this.currentElement ?? throw SVGParseException("Invalid document. Root element must be <svg>")
        if (!(current is TextContainer)) {
            throw SVGParseException(
                "Invalid document. <tref> elements are only valid inside <text> or <tspan> elements.")
        }
        let obj: TRef = TRef()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesTRef(obj, data)
        this.currentElement().addChild(obj)
    }

    private func parseAttributesTRef(obj: TRef, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "href" => obj.href = val
                case _ => ()
            }
        }
    }

    private func zwitch(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Switch = Switch()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        this.currentElement().addChild(obj)
        this.currentElement = obj
    }

    private func line(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Line2 = Line2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesLine(obj, data)
        this.currentElement().addChild(obj)
    }

    private func parseAttributesLine(obj: Line2, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "x1" => obj.x1 = parseLength(val)
                case "y1" => obj.y1 = parseLength(val)
                case "x2" => obj.x2 = parseLength(val)
                case "y2" => obj.y2 = parseLength(val)
                case _ => ()
            }
        }
    }

    private func polyline(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: PolyLine = PolyLine()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesPolyLine(obj, data, "polyline")
        this.currentElement().addChild(obj)
    }

    private func parseAttributesPolyLine(obj: PolyLine, data: StaxXmlPullParser, tag: String): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "points" =>
                    let scan: TextScanner = TextScanner(val)
                    let points: ArrayList<Float64> = ArrayList<Float64>()
                    scan.skipWhitespace()
                    while (!scan.empty()) {
                        let x: Float64 = scan.nextFloat()
                        if (x.isNaN()) {
                            throw SVGParseException(
                                "Invalid <" + tag + "> points attribute. Non-coordinate content found in list.")
                        }
                        scan.skipCommaWhitespace()
                        let y: Float64 = scan.nextFloat()
                        if (y.isNaN()) {
                            throw SVGParseException(
                                "Invalid <" + tag + "> points attribute. There should be an even number of coordinates."
                            )
                        }
                        scan.skipCommaWhitespace()
                        points.append(x)
                        points.append(y)
                    }
                    obj.points = ArrayList<Float64>(points.size)
                    var j: Int64 = 0
                    for (point in points) {
                        obj.points.insert(j, point)
                        j++
                    }

                case _ => ()
            }
        }
    }

    private func polygon(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Polygon2 = Polygon2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesPolyLine(obj, data, "polygon")
        this.currentElement().addChild(obj)
    }

    private func parseAttributesTextPosition(obj: TextPositionedContainer, data: StaxXmlPullParser): Unit {
        if (data.getAttributeCount() <= 0) {
            return
        }
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "x" => obj.x = parseLengthList(val)
                case "y" => obj.y = parseLengthList(val)
                case "dx" => obj.dx = parseLengthList(val)
                case "hredyf" => obj.dy = parseLengthList(val)
                case _ => ()
            }
        }
    }

    private static func parseLengthList(val: String): ArrayList<SVGLength> {
        if (val.size == 0) {
            throw SVGParseException("Invalid length list (empty string)")
        }
        let coords: ArrayList<SVGLength> = ArrayList<SVGLength>()

        let scan: TextScanner = TextScanner(val)
        scan.skipWhitespace()

        while (!scan.empty()) {
            let scalar: Float64 = scan.nextFloat()
            if (scalar.isNaN()) {
                throw SVGParseException("Invalid length list value: " + scan.ahead())
            }
            var uni: String = scan.nextUnit()
            if (uni == "") {
                uni = Units.px
            }
            coords.append(SVGLength(scalar, u: uni))
            scan.skipCommaWhitespace()
        }
        return coords
    }

    private func rect(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Rect2 = Rect2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesRect(obj, data)
        this.currentElement().addChild(obj)
    }

    private func parseAttributesRect(obj: Rect2, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "x" => obj.x = parseLength(val)
                case "y" => obj.y = parseLength(val)
                case "width" =>
                    obj.width = parseLength(val)
                    if (obj.width.isNegative()) {
                        throw SVGParseException("Invalid <rect> element. width cannot be negative")
                    }
                case "height" =>
                    obj.height = parseLength(val)
                    if (obj.height.isNegative()) {
                        throw SVGParseException("Invalid <rect> element. height cannot be negative")
                    }
                case "rx" =>
                    obj.rx = parseLength(val)
                    if (obj.rx.isNegative()) {
                        throw SVGParseException("Invalid <rect> element. rx cannot be negative")
                    }
                case "ry" =>
                    obj.ry = parseLength(val)
                    if (obj.ry.isNegative()) {
                        throw SVGParseException("Invalid <rect> element. ry cannot be negative")
                    }
                case _ => ()
            }
        }
    }

    private func circle(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Circle2 = Circle2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesCircle(obj, data)
        this.currentElement().addChild(obj)
    }

    private func parseAttributesCircle(obj: Circle2, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "cx" => obj.cx = parseLength(val)
                case "cy" => obj.cy = parseLength(val)
                case "r" =>
                    obj.r = parseLength(val)
                    if (obj.r.isNegative()) {
                        throw SVGParseException("Invalid <circle> element. r cannot be negative")
                    }
                case _ => ()
            }
        }
    }

    private func ellipse(data: StaxXmlPullParser): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Ellipse2 = Ellipse2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesEllipse(obj, data)
        this.currentElement().addChild(obj)
    }

    private func parseAttributesEllipse(obj: Ellipse2, data: StaxXmlPullParser): Unit {
        for (i in 0..data.getAttributeCount()) {
            let val: String = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "cx" => obj.cx = parseLength(val)
                case "cy" => obj.cy = parseLength(val)
                case "rx" =>
                    obj.rx = parseLength(val)
                    if (obj.rx.isNegative()) {
                        throw SVGParseException("Invalid <ellipse> element. rx cannot be negative")
                    }
                case "ry" =>
                    obj.ry = parseLength(val)
                    if (obj.ry.isNegative()) {
                        throw SVGParseException("Invalid <ellipse> element. ry cannot be negative")
                    }
                case _ => ()
            }
        }
    }

    func endElement(name: String): Unit {
        if (this.ignoring) {
            this.ignoreDepth--
            if (this.ignoreDepth == 0) {
                this.ignoring = false
            }
            return
        }
        match (name) {
            case title where title == SVGXMLConstants.SVG_TITLE_ATTRIBUTE || title == SVGXMLConstants.SVG_DESC_TAG =>
                this.inMetadataElement = false
                if (this.metadataElementContents != "") {
                    if (this.metadataTag == SVGXMLConstants.SVG_TITLE_TAG) {
                        this.svgDocument().setTitle(this.metadataElementContents.toString())
                    } else if (this.metadataTag == SVGXMLConstants.SVG_DESC_TAG) {
                        this.svgDocument().setDesc(this.metadataElementContents.toString())
                    }
                    this.metadataElementContents = ""
                }
                return
            case style where style == SVGXMLConstants.SVG_STYLE_TAG => if (this.styleElementContents != "") {
                parseCSSStyleSheet(this.styleElementContents)
                this.styleElementContents = ""
                return
            }
            case svg where svg == SVGXMLConstants.SVG_SVG_TAG || svg == SVGXMLConstants.SVG_G_TAG || svg ==
                SVGXMLConstants.SVG_DEFS_TAG || svg == SVGXMLConstants.SVG_A_TAG || svg == SVGXMLConstants.SVG_USE_TAG
                || svg == SVGXMLConstants.SVG_IMAGE_TAG || svg == SVGXMLConstants.SVG_TEXT_TAG || svg == SVGXMLConstants.
                SVG_TSPAN_TAG || svg == SVGXMLConstants.SVG_SWITCH_TAG || svg == SVGXMLConstants.SVG_SYMBOL_TAG
                || svg == SVGXMLConstants.SVG_MARKER_TAG || svg == SVGXMLConstants.SVG_LINEAR_GRADIENT_TAG || svg ==
                SVGXMLConstants.SVG_RADIAL_GRADIENT_TAG || svg == SVGXMLConstants.SVG_STOP_TAG
                || svg == SVGXMLConstants.SVG_CLIP_PATH_TAG || svg == SVGXMLConstants.SVG_TEXT_PATH_TAG || svg ==
                SVGXMLConstants.SVG_PATTERN_TAG || svg == SVGXMLConstants.SVG_VIEW_TAG || svg == SVGXMLConstants.
                SVG_MASK_TAG => if (let Some(v) <- this.currentElement() as SvgObject) {
                this.currentElement = v.parent
            } else {
                throw SVGParseException("Unbalanced end element </${name}> found")
            }
            case _ => ()
        }
    }

    private func parseCSSStyleSheet(sheet: String): Unit {
        let cssp: CSSParser = CSSParser(rendererMediaType: "screen", source: Source.Document,
            externalFileResolver: this.externalFileResolver)
        this.svgDocument().addCSSRules(cssp.parse(sheet))
    }

    private func path(data: StaxXmlPullParser) {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let obj: Path2 = Path2()
        obj.document = this.svgDocument
        obj.parent = this.currentElement
        parseAttributesCore(obj, data)
        parseAttributesStyle(obj, data)
        parseAttributesTransform(obj, data)
        parseAttributesConditional(obj, data)
        parseAttributesPath(obj, data)
        this.currentElement().addChild(obj)
    }

    private func parseAttributesPath(obj: Path2, data: StaxXmlPullParser) {
        for (i in 0..data.getAttributeCount()) {
            let val = data.getAttributeValue(i)
            match (data.getAttributeName(i)) {
                case "d" => obj.d = parsePath(val)
                case "pathLength" =>
                    obj.pathLength = parseFloat(val)
                    if (obj.pathLength < 0.0) {
                        throw SVGParseException("Invalid <path> element. pathLength cannot be negative")
                    }
                case _ => ()
            }
        }
    }

    static func parsePath(content: String): PathDefinition {
        let scan: TextScanner = TextScanner(content)
        var currentX: Float64 = 0.0
        var currentY: Float64 = 0.0
        var lastMoveX: Float64 = 0.0
        var lastMoveY: Float64 = 0.0
        var lastControlX: Float64 = 0.0
        var lastControlY = 0.0
        var x: Float64 = 0.0
        var y: Float64 = 0.0
        var x1: Float64 = 0.0
        var y1: Float64 = 0.0
        var x2: Float64 = 0.0
        var y2: Float64 = 0.0
        var rx: Float64 = 0.0
        var ry: Float64 = 0.0
        var xAxisRotation: Float64 = 0.0
        var largeArcFlag: Bool = false
        var sweepFlag: Bool = false
        let path: PathDefinition = PathDefinition()
        path.d = content
        if (scan.empty()) {
            return path
        }

        var pathCommand: Byte = scan.nextChar()
        if (pathCommand != b'M' && pathCommand != b'm') {
            return path
        }

        while (true) {
            scan.skipWhitespace()

            match (pathCommand) {
                case b'M' => return path
                case b'm' =>
                    return path
                    x = scan.nextFloat()
                    y = scan.checkedNextFloat(x)
                    if (y.isNaN()) {
                        return path
                    }

                    if (pathCommand == b'm' && !path.isEmpty()) {
                        x += currentX
                        y += currentY
                    }
                    path.moveTo(x, y)
                    currentX = x
                    lastMoveX = x
                    lastControlX = x
                    currentY = y
                    lastMoveY = y
                    lastControlY = y
                    pathCommand = if (pathCommand == b'm') {
                        b'l'
                    } else {
                        b'L'
                    }
                case b'L' => return path
                case b'l' =>
                    return path
                    x = scan.nextFloat()
                    y = scan.checkedNextFloat(x)
                    if (y.isNaN()) {
                        return path
                    }
                    if (pathCommand == b'l') {
                        x += currentX
                        y += currentY
                    }
                    path.lineTo(x, y)
                    currentX = x
                    lastControlX = x
                    currentY = y
                    lastControlY = y
                case b'C' => return path
                case b'c' =>
                    x1 = scan.nextFloat()
                    y1 = scan.checkedNextFloat(x1)
                    x2 = scan.checkedNextFloat(y1)
                    y2 = scan.checkedNextFloat(x2)
                    x = scan.checkedNextFloat(y2)
                    y = scan.checkedNextFloat(x)
                    if (y.isNaN()) {
                        return path
                    }
                    if (pathCommand == b'c') {
                        x += currentX
                        y += currentY
                        x1 += currentX
                        y1 += currentY
                        x2 += currentX
                        y2 += currentY
                    }
                    path.cubicTo(x1, y1, x2, y2, x, y)
                    lastControlX = x2
                    lastControlY = y2
                    currentX = x
                    currentY = y
                case b'S' => return path
                case b's' =>
                    x1 = 2.0 * currentX - lastControlX
                    y1 = 2.0 * currentY - lastControlY
                    x2 = scan.nextFloat()
                    y2 = scan.checkedNextFloat(x2)
                    x = scan.checkedNextFloat(y2)
                    y = scan.checkedNextFloat(x)
                    if (y.isNaN()) {
                        return path
                    }
                    if (pathCommand == b's') {
                        x += currentX
                        y += currentY
                        x2 += currentX
                        y2 += currentY
                    }
                    path.cubicTo(x1, y1, x2, y2, x, y)
                    lastControlX = x2
                    lastControlY = y2
                    currentX = x
                    currentY = y
                case b'Z' => return path
                case b'z' =>
                    path.close()
                    currentX = lastMoveX
                    lastControlX = lastMoveX
                    currentY = lastMoveY
                    lastControlY = lastMoveY
                case b'H' => return path
                case b'h' =>
                    x = scan.nextFloat()
                    if (x.isNaN()) {
                        return path
                    }
                    if (pathCommand == b'h') {
                        x += currentX
                    }
                    path.lineTo(x, currentY)
                    currentX = x
                    lastControlX = x
                case b'V' => return path
                case b'v' =>
                    y = scan.nextFloat()
                    if (y.isNaN()) {
                        return path
                    }
                    if (pathCommand == b'v') {
                        y += currentY
                    }
                    path.lineTo(currentX, y)
                    currentY = y
                    lastControlY = y
                case b'Q' => return path
                case b'q' =>
                    x1 = scan.nextFloat()
                    y1 = scan.checkedNextFloat(x1)
                    x = scan.checkedNextFloat(y1)
                    y = scan.checkedNextFloat(x)
                    if (y.isNaN()) {
                        return path
                    }
                    if (pathCommand == b'q') {
                        x += currentX
                        y += currentY
                        x1 += currentX
                        y1 += currentY
                    }
                    path.quadTo(x1, y1, x, y)
                    lastControlX = x1
                    lastControlY = y1
                    currentX = x
                    currentY = y
                case b'T' => return path
                case b't' =>
                    x1 = 2.0 * currentX - lastControlX
                    y1 = 2.0 * currentY - lastControlY
                    x = scan.nextFloat()
                    y = scan.checkedNextFloat(x)
                    if (y.isNaN()) {
                        return path
                    }
                    if (pathCommand == b't') {
                        x += currentX
                        y += currentY
                    }
                    path.quadTo(x1, y1, x, y)
                    lastControlX = x1
                    lastControlY = y1
                    currentX = x
                    currentY = y
                case b'A' => return path
                case b'a' =>
                    rx = scan.nextFloat()
                    ry = scan.checkedNextFloat(rx)
                    xAxisRotation = scan.checkedNextFloat(ry)
                    largeArcFlag = scan.checkedNextFlag(xAxisRotation)
                    sweepFlag = scan.checkedNextFlag(largeArcFlag)
                    x = scan.checkedNextFloat(sweepFlag)
                    y = scan.checkedNextFloat(x)
                    if (y.isNaN() || rx < 0.0 || ry < 0.0) {
                        return path
                    }
                    if (pathCommand == b'a') {
                        x += currentX
                        y += currentY
                    }
                    path.arcTo(rx, ry, xAxisRotation, largeArcFlag, sweepFlag, x, y)
                    currentX = x
                    lastControlX = x
                    currentY = y
                    lastControlY = y
                case _ => return path
            }

            scan.skipCommaWhitespace()
            if (scan.empty()) {
                break
            }
            if (scan.hasLetter()) {
                pathCommand = scan.nextChar()
            }
        }
        return path
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
                return parseColour(val)
            } catch (var4: SVGParseException) {
                return SvgPaint()
            }
        }
    }

    static func parseColour(val: String): Colour {
        if (val.startsWith("#") && val.count("#") == 1) {
            return Colour(Color(UInt32.parse(val.replace("#", "0x"))))
        } else {
            return Colour(Color(0x000000))
        }
    }

    static func parseFillRule(val: String): String {
        if ("nonzero" == val) {
            return FillRule().NonZero
        }
        if ("evenodd" == (val)) {
            return FillRule().EvenOdd
        }
        return ""
    }
}

class ColourKeywords {
    private static let colourKeywords: HashMap<String, UInt32> = HashMap<String, UInt32>(47)

    init() {}

    static func getColour(colourName: String): ?UInt32 {
        return colourKeywords.get(colourName)
    }

    static init() {
        colourKeywords.put("aliceblue", 0xf0f8ff)
        colourKeywords.put("antiquewhite", 0xfaebd7)
        colourKeywords.put("aqua", 0x00ffff)
        colourKeywords.put("aquamarine", 0x7fffd4)
        colourKeywords.put("azure", 0xf0ffff)
        colourKeywords.put("beige", 0xf5f5dc)
        colourKeywords.put("bisque", 0xffe4c4)
        colourKeywords.put("black", 0x000000)
        colourKeywords.put("blanchedalmond", 0xffebcd)
        colourKeywords.put("blue", 0x0000ff)
        colourKeywords.put("blueviolet", 0x8a2be2)
        colourKeywords.put("brown", 0xa52a2a)
        colourKeywords.put("burlywood", 0xdeb887)
        colourKeywords.put("cadetblue", 0x5f9ea0)
        colourKeywords.put("chartreuse", 0x7fff00)
        colourKeywords.put("chocolate", 0xd2691e)
        colourKeywords.put("coral", 0xff7f50)
        colourKeywords.put("cornflowerblue", 0x6495ed)
        colourKeywords.put("cornsilk", 0xfff8dc)
        colourKeywords.put("crimson", 0xdc143c)
        colourKeywords.put("cyan", 0x00ffff)
        colourKeywords.put("darkblue", 0x00008b)
        colourKeywords.put("darkcyan", 0x008b8b)
        colourKeywords.put("darkgoldenrod", 0xb8860b)
        colourKeywords.put("darkgray", 0xa9a9a9)
        colourKeywords.put("darkgreen", 0x006400)
        colourKeywords.put("darkgrey", 0xa9a9a9)
        colourKeywords.put("darkkhaki", 0xbdb76b)
        colourKeywords.put("darkmagenta", 0x8b008b)
        colourKeywords.put("darkolivegreen", 0x556b2f)
        colourKeywords.put("darkorange", 0xff8c00)
        colourKeywords.put("darkorchid", 0x9932cc)
        colourKeywords.put("darkred", 0x8b0000)
        colourKeywords.put("darksalmon", 0xe9967a)
        colourKeywords.put("darkseagreen", 0x8fbc8f)
        colourKeywords.put("darkslateblue", 0x483d8b)
        colourKeywords.put("darkslategray", 0x2f4f4f)
        colourKeywords.put("darkslategrey", 0x2f4f4f)
        colourKeywords.put("darkturquoise", 0x00ced1)
        colourKeywords.put("darkviolet", 0x9400d3)
        colourKeywords.put("deeppink", 0xff1493)
        colourKeywords.put("deepskyblue", 0x00bfff)
        colourKeywords.put("dimgray", 0x696969)
        colourKeywords.put("dimgrey", 0x696969)
        colourKeywords.put("dodgerblue", 0x1e90ff)
        colourKeywords.put("firebrick", 0xb22222)
        colourKeywords.put("floralwhite", 0xfffaf0)
        colourKeywords.put("forestgreen", 0x228b22)
        colourKeywords.put("fuchsia", 0xff00ff)
        colourKeywords.put("gainsboro", 0xdcdcdc)
        colourKeywords.put("ghostwhite", 0xf8f8ff)
        colourKeywords.put("gold", 0xffd700)
        colourKeywords.put("goldenrod", 0xdaa520)
        colourKeywords.put("gray", 0x808080)
        colourKeywords.put("green", 0x008000)
        colourKeywords.put("greenyellow", 0xadff2f)
        colourKeywords.put("grey", 0x808080)
        colourKeywords.put("honeydew", 0xf0fff0)
        colourKeywords.put("hotpink", 0xff69b4)
        colourKeywords.put("indianred", 0xcd5c5c)
        colourKeywords.put("indigo", 0x4b0082)
        colourKeywords.put("ivory", 0xfffff0)
        colourKeywords.put("khaki", 0xf0e68c)
        colourKeywords.put("lavender", 0xe6e6fa)
        colourKeywords.put("lavenderblush", 0xfff0f5)
        colourKeywords.put("lawngreen", 0x7cfc00)
        colourKeywords.put("lemonchiffon", 0xfffacd)
        colourKeywords.put("lightblue", 0xadd8e6)
        colourKeywords.put("lightcoral", 0xf08080)
        colourKeywords.put("lightcyan", 0xe0ffff)
        colourKeywords.put("lightgoldenrodyellow", 0xfafad2)
        colourKeywords.put("lightgray", 0xd3d3d3)
        colourKeywords.put("lightgreen", 0x90ee90)
        colourKeywords.put("lightgrey", 0xd3d3d3)
        colourKeywords.put("lightpink", 0xffb6c1)
        colourKeywords.put("lightsalmon", 0xffa07a)
        colourKeywords.put("lightseagreen", 0x20b2aa)
        colourKeywords.put("lightskyblue", 0x87cefa)
        colourKeywords.put("lightslategray", 0x778899)
        colourKeywords.put("lightslategrey", 0x778899)
        colourKeywords.put("lightsteelblue", 0xb0c4de)
        colourKeywords.put("lightyellow", 0xffffe0)
        colourKeywords.put("lime", 0x00ff00)
        colourKeywords.put("limegreen", 0x32cd32)
        colourKeywords.put("linen", 0xfaf0e6)
        colourKeywords.put("magenta", 0xff00ff)
        colourKeywords.put("maroon", 0x800000)
        colourKeywords.put("mediumaquamarine", 0x66cdaa)
        colourKeywords.put("mediumblue", 0x0000cd)
        colourKeywords.put("mediumorchid", 0xba55d3)
        colourKeywords.put("mediumpurple", 0x9370db)
        colourKeywords.put("mediumseagreen", 0x3cb371)
        colourKeywords.put("mediumslateblue", 0x7b68ee)
        colourKeywords.put("mediumspringgreen", 0x00fa9a)
        colourKeywords.put("mediumturquoise", 0x48d1cc)
        colourKeywords.put("mediumvioletred", 0xc71585)
        colourKeywords.put("midnightblue", 0x191970)
        colourKeywords.put("mintcream", 0xf5fffa)
        colourKeywords.put("mistyrose", 0xffe4e1)
        colourKeywords.put("moccasin", 0xffe4b5)
        colourKeywords.put("navajowhite", 0xffdead)
        colourKeywords.put("navy", 0x000080)
        colourKeywords.put("oldlace", 0xfdf5e6)
        colourKeywords.put("olive", 0x808000)
        colourKeywords.put("olivedrab", 0x6b8e23)
        colourKeywords.put("orange", 0xffa500)
        colourKeywords.put("orangered", 0xff4500)
        colourKeywords.put("orchid", 0xda70d6)
        colourKeywords.put("palegoldenrod", 0xeee8aa)
        colourKeywords.put("palegreen", 0x98fb98)
        colourKeywords.put("paleturquoise", 0xafeeee)
        colourKeywords.put("palevioletred", 0xdb7093)
        colourKeywords.put("papayawhip", 0xffefd5)
        colourKeywords.put("peachpuff", 0xffdab9)
        colourKeywords.put("peru", 0xcd853f)
        colourKeywords.put("pink", 0xffc0cb)
        colourKeywords.put("plum", 0xdda0dd)
        colourKeywords.put("powderblue", 0xb0e0e6)
        colourKeywords.put("purple", 0x800080)
        colourKeywords.put("rebeccapurple", 0x663399)
        colourKeywords.put("red", 0xff0000)
        colourKeywords.put("rosybrown", 0xbc8f8f)
        colourKeywords.put("royalblue", 0x4169e1)
        colourKeywords.put("saddlebrown", 0x8b4513)
        colourKeywords.put("salmon", 0xfa8072)
        colourKeywords.put("sandybrown", 0xf4a460)
        colourKeywords.put("seagreen", 0x2e8b57)
        colourKeywords.put("seashell", 0xfff5ee)
        colourKeywords.put("sienna", 0xa0522d)
        colourKeywords.put("silver", 0xc0c0c0)
        colourKeywords.put("skyblue", 0x87ceeb)
        colourKeywords.put("slateblue", 0x6a5acd)
        colourKeywords.put("slategray", 0x708090)
        colourKeywords.put("slategrey", 0x708090)
        colourKeywords.put("snow", 0xfffafa)
        colourKeywords.put("springgreen", 0x00ff7f)
        colourKeywords.put("steelblue", 0x4682b4)
        colourKeywords.put("tan", 0xd2b48c)
        colourKeywords.put("teal", 0x008080)
        colourKeywords.put("thistle", 0xd8bfd8)
        colourKeywords.put("tomato", 0xff6347)
        colourKeywords.put("turquoise", 0x40e0d0)
        colourKeywords.put("violet", 0xee82ee)
        colourKeywords.put("wheat", 0xf5deb3)
        colourKeywords.put("white", 0xffff)
        colourKeywords.put("whitesmoke", 0xF5F5F5)
        colourKeywords.put("yellow", 0xff00)
        colourKeywords.put("yellowgreen", 0x9acd32)
        colourKeywords.put("transparent", 0x000000)
    }
}
