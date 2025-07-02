/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

// px2vp 依赖 UI 实例/线程上下文，异步解析渲染线程上可能返回 None。
// 这里缓存一次 px->vp 比例并做密度兜底，避免异常中断整个渲染流程。
private let pxToVpRatioBits: AtomicUInt64 = AtomicUInt64(0)

private func resolvePxToVpRatioFromDensity(): Float64 {
    try {
        let density: Float64 = Float64(getDefaultDisplaySync().densityPixels)
        if (density > 0.0) {
            return 1.0 / density
        }
    } catch (e: Exception) {
        return 1.0
    }
    return 1.0
}

private func resolvePxToVpRatio(): Float64 {
    try {
        if (let Some(v) <- px2vp(1.px)) {
            if (v.value > 0.0) {
                return v.value
            }
        }
    } catch (e: Exception) {
        return resolvePxToVpRatioFromDensity()
    }
    return resolvePxToVpRatioFromDensity()
}

func px2vpValue(value: Float64): Float64 {
    var ratioBits = pxToVpRatioBits.load()
    if (ratioBits == 0) {
        let resolvedBits = resolvePxToVpRatio().toBits()
        if (pxToVpRatioBits.compareAndSwap(0, resolvedBits)) {
            ratioBits = resolvedBits
        } else {
            ratioBits = pxToVpRatioBits.load()
        }
    }
    return value * Float64.fromBits(ratioBits)
}

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
    public var ignoring: Bool = false
    private var ignoreDepth: Int64 = 0
    var enableInternalEntities: Bool = true
    var externalFileResolver: SVGExternalFileResolver = SVGExternalFileResolver()
    private var metadataTag: String = ""
    private var metadataElementContents: String = ""
    private var styleElementContents: String = ""
    private var inMetadataElement: Bool = false
    private var convertTransformsToVp: Bool = true

    public func parseString(s: String): SVGBase {
        startDocument()
        let buf = ByteBuffer()
        buf.write(s.toArray())
        let parser: StaxXmlPullParser = StaxXmlPullParser(buf)
        while (parser.getEventType() != XmlPullParserEvent.END_DOCUMENT) {
            let event = parser.next()
            match (event) {
                case START_ELEMENT =>
                    startElement(parser)
                case END_ELEMENT =>
                    endElement(parser.getName())
                case TEXT_CHARACTERS =>
                    if (parser.getName() == "style") {
                        this.ignoring = false
                        style(parser, parser.getText())
                    } else if (!this.ignoring) {
                        appendText(parser.getText())
                    }
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

    public func setConvertTransformsToVp(enable: Bool): SVGParserImpl {
        this.convertTransformsToVp = enable
        return this
    }

    private func transformLength(value: Float64): Float64 {
        if (this.convertTransformsToVp) {
            return px2vpValue(value)
        }
        return value
    }

    /**
     * 将文本追加到当前文本容器。
     *
     * @param text 待追加的文本。
     * @throws SVGParseException 当文档缺少根元素时抛出。
     */
    private func appendText(text: String): Unit {
        if (this.currentElement.isNone()) {
            throw SVGParseException("Invalid document. Root element must be <svg>")
        }
        let current = this.currentElement()
        if (!(current is TextContainer)) {
            return
        }
        let sequence = TextSequence(text)
        sequence.document = this.svgDocument
        sequence.parent = this.currentElement
        if (let Some(root) <- (current as TextRoot)) {
            sequence.setTextRoot(root)
        } else if (let Some(child) <- (current as TextChild)) {
            sequence.setTextRoot(child.getTextRoot())
        }
        current.addChild(sequence)
    }

    /**
     * 解析元素的核心属性。
     *
     * @param obj 待解析的元素。
     * @param data XML 属性数据。
     * @throws SVGParseException 当 xml:space 属性值非法时抛出。
     */
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

    /**
     * 解析 SVG transform 属性。
     *
     * @param val transform 属性值。
     * @return 解析后的变换矩阵。
     * @throws SVGParseException 当 transform 属性语法非法时抛出。
     */
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
                    m.setValues(a: a, b: b, c: c, d: d, tx: transformLength(e), ty: transformLength(f))
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
                        matrix.translate(transformLength(tx), y: 0.0)
                    } else {
                        matrix.translate(transformLength(tx), y: transformLength(ty))
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
                        matrix.rotate(ang, cx: transformLength(cx), cy: transformLength(cy))
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
                    matrix.skew(tan(ang * (Float64.getPI() / 180.0)), 0.0)
                case "skewY" =>
                    scan.skipWhitespace()
                    let ang2: Float64 = scan.nextFloat()
                    scan.skipWhitespace()
                    if (ang2.isNaN() || !scan.consume(")")) {
                        throw SVGParseException("Invalid transform list: " + val)
                    }
                    matrix.skew(0.0, tan(ang2 * (Float64.getPI() / 180.0)))
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

    /**
     * 解析 g 元素。
     *
     * @param data XML 属性数据。
     * @throws SVGParseException 当文档缺少根 svg 元素或元素属性解析失败时抛出。
     */
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

    /**
     * 解析 defs 元素。
     *
     * @param data XML 属性数据。
     * @throws SVGParseException 当文档缺少根 svg 元素或元素属性解析失败时抛出。
     */
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

    /**
     * 解析 a 元素。
     *
     * @param data XML 属性数据。
     * @throws SVGParseException 当文档缺少根 svg 元素或元素属性解析失败时抛出。
     */
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
                case "href" | "xlink:href" | "xlink_href" => obj.href = data.getAttributeValue(i)
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
                case "href" | "xlink:href" | "xlink_href" => obj.href = val
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
            if (let Some(s) <- (obj as Svg)) {
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
                result.add(feature[SVGParserImpl.FEATURE_STRING_PREFIX.size..])
            } else {
                result.add("UNSUPPORTED")
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
            result.add(language)
            scan.skipWhitespace()
        }
        return result
    }

    private static func parseRequiredFormats(content: String): HashSet<String> {
        let scan: TextScanner = TextScanner(content)
        var result: HashSet<String> = HashSet<String>()
        while (!scan.empty()) {
            let mimetype: String = scan.nextToken()
            result.add(mimetype)
            scan.skipWhitespace()
        }
        return result
    }

    static func parseFontFamily(content: String): ArrayList<String> {
        var fonts: ArrayList<String> = ArrayList<String>()
        let scan: TextScanner = TextScanner(content)
        while (true) {
            var item:  String = scan.nextQuotedString()
            if (item == "") {
                item = scan.nextTokenWithWhitespace(',')
            }
            if (item == "") {
                break
            }
            if (fonts.isEmpty()) {
                fonts = ArrayList<String>()
            }
            fonts.add(item)
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
            return
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
        } else if (name == SVGXMLConstants.SVG_TREF_TAG) {
            tref(data)
        } else if (name == SVGXMLConstants.SVG_TEXT_TAG) {
            text(data)
        } else if (name == SVGXMLConstants.SVG_TSPAN_TAG) {
            tspan(data)
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
            style(data, "")
        } else {
            this.ignoring = true
            this.ignoreDepth = 1
        }
    }

    private func text(data: StaxXmlPullParser): Unit {
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
        this.currentElement().addChild(obj)
        this.currentElement = obj
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
                        throw SVGParseException("Invalid <Image> element. width cannot be negative")
                    }
                case "height" =>
                    obj.height = parseLength(val)
                    if (obj.height.isNegative()) {
                        throw SVGParseException("Invalid <Image> element. height cannot be negative")
                    }
                case "href" | "xlink:href" | "xlink_href" => obj.href = val
                case "preserveAspectRatio" => SVGParserImpl.parsePreserveAspectRatio(obj, val)
                case _ => ()
            }
        }
    }

    private func style(data: StaxXmlPullParser, content: String): Unit {
        styleElementContents = content
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
                } else if ("auto-start-reverse" == val) {
                    obj.orient = Float64.NaN
                    obj.orientAutoStartReverse = true
                } else {
                    obj.orient = try {
                        parseFloat(val)
                    } catch (e: Exception) {
                        0.0
                    }
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
                    obj.gradientUnitsAreUserSet = true
                } else if ("userSpaceOnUse" == val) {
                    obj.gradientUnitsAreUser = true
                    obj.gradientUnitsAreUserSet = true
                } else {
                    throw SVGParseException("Invalid value for attribute gradientUnits")
                }
                case "gradientTransform" => obj.gradientTransform = parseTransformList(val)
                case "spreadMethod" =>
                    try {
                        obj.spreadMethod.val = val
                        obj.spreadMethodSet = true
                    } catch (e: SVGParseException) {
                        throw SVGParseException("Invalid spreadMethod attribute. \"" + val + "\" is not a valid value.")
                    }
                    break
                case "href" | "xlink:href" | "xlink_href" => obj.href = val
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
                case "offset" => obj.offset = parseGradientOffset(val)
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
                if (scalar > 1.0) {
                    return 1.0
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
                    obj.clipPathUnitsAreUserSpecified = true
                    obj.clipPathUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.clipPathUnitsAreUserSpecified = true
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
                case "href" | "xlink:href" | "xlink_href" => obj.href = val
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
                    obj.patternUnitsAreUserSet = true
                    obj.patternUnitsAreUser = false
                } else if ("userSpaceOnUse" == val) {
                    obj.patternUnitsAreUserSet = true
                    obj.patternUnitsAreUser = true
                } else {
                    throw SVGParseException("Invalid value for attribute patternUnits")
                }
                case "patternContentUnits" =>
                    if ("objectBoundingBox" == val) {
                        obj.patternContentUnitsAreUserSet = true
                        obj.patternContentUnitsAreUser = false
                    } else if ("userSpaceOnUse" == val) {
                        obj.patternContentUnitsAreUserSet = true
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
                case "href" | "xlink:href" | "xlink_href" => obj.href = val

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
        if (let Some(root) <- (current as TextRoot)) {
            obj.setTextRoot(root)
        } else if (let Some(child) <- (current as TextChild)) {
            obj.setTextRoot(child.getTextRoot())
        }
        currentElement().addChild(obj)
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
                case "href" | "xlink:href" | "xlink_href" => obj.href = val
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
                        points.add(x)
                        points.add(y)
                    }
                    obj.points = ArrayList<Float64>(points.size)
                    var j: Int64 = 0
                    for (point in points) {
                        obj.points.add(point, at: j)
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
                case "dy" => obj.dy = parseLengthList(val)
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
            coords.add(SVGLength(scalar, u: uni))
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
                SVG_MASK_TAG => if (let Some(v) <- (this.currentElement() as SvgObject)) {
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
                case b'M' | b'm' =>
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
                case b'L' | b'l' =>
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
                case b'C' | b'c' =>
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
                case b'S' | b's' =>
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
                case b'Z' | b'z' =>
                    path.close()
                    currentX = lastMoveX
                    lastControlX = lastMoveX
                    currentY = lastMoveY
                    lastControlY = lastMoveY
                case b'H' | b'h' =>
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
                case b'V' | b'v' =>
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
                case b'Q' | b'q' =>
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
                case b'T' | b't' =>
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
                case b'A' | b'a' =>
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

    // 颜色解析：命名为 ArkTS SVGParserImpl.parseColour + SVGRenderer.getRgbaColor 的合并实现。
    // Cangjie 侧把颜色保存为 Color，因此这里必须一次性解析出正确的 ARGB。
    static func parseColour(val: String): Colour {
        let s: String = val.trimAscii()
        if (s.size == 0) {
            throw SVGParseException("Invalid colour value: " + val)
        }
        let lower: String = s.toAsciiLower()
        if (lower == "transparent") {
            return Colour(SVGParserImpl.colourFromArgb(0x00000000u32))
        }
        if (let Some(rgb) <- ColourKeywords.getColour(lower)) {
            return Colour(SVGParserImpl.colourFromArgb(0xFF000000u32 | rgb))
        }
        if (s.startsWith("#")) {
            return SVGParserImpl.parseHexColour(s, val)
        }
        if (lower.startsWith("rgb")) {
            return SVGParserImpl.parseRgbColour(s, val)
        }
        if (lower.startsWith("hsl")) {
            return SVGParserImpl.parseHslColour(s, val)
        }
        throw SVGParseException("Invalid colour value: " + val)
    }

    // 用 0xAARRGGBB 构造 Color。Color(UInt32) 在只给出 RGB 时会把 alpha 补成 0xFF，
    // 因此全透明色需要单独走通道构造函数，避免丢失 RGB 或变成不透明黑。
    private static func colourFromArgb(argb: UInt32): Color {
        let alpha: UInt32 = (argb >> 24) & 0xFFu32
        if (alpha == 0u32) {
            let red: UInt8 = UInt8((argb >> 16) & 0xFFu32)
            let green: UInt8 = UInt8((argb >> 8) & 0xFFu32)
            let blue: UInt8 = UInt8(argb & 0xFFu32)
            return Color(red, green, blue, alpha: 0.0)
        }
        return Color(argb)
    }

    private static func parseHexColour(s: String, original: String): Colour {
        let hex: String = s[1..]
        let n: Int64 = hex.size
        if (n == 3) {
            let r: UInt32 = SVGParserImpl.hexPair(hex[0], hex[0], original)
            let g: UInt32 = SVGParserImpl.hexPair(hex[1], hex[1], original)
            let b: UInt32 = SVGParserImpl.hexPair(hex[2], hex[2], original)
            return Colour(SVGParserImpl.colourFromArgb(0xFF000000u32 | (r << 16) | (g << 8) | b))
        } else if (n == 4) {
            let r: UInt32 = SVGParserImpl.hexPair(hex[0], hex[0], original)
            let g: UInt32 = SVGParserImpl.hexPair(hex[1], hex[1], original)
            let b: UInt32 = SVGParserImpl.hexPair(hex[2], hex[2], original)
            let a: UInt32 = SVGParserImpl.hexPair(hex[3], hex[3], original)
            return Colour(SVGParserImpl.colourFromArgb((a << 24) | (r << 16) | (g << 8) | b))
        } else if (n == 6) {
            let r: UInt32 = SVGParserImpl.hexPair(hex[0], hex[1], original)
            let g: UInt32 = SVGParserImpl.hexPair(hex[2], hex[3], original)
            let b: UInt32 = SVGParserImpl.hexPair(hex[4], hex[5], original)
            return Colour(SVGParserImpl.colourFromArgb(0xFF000000u32 | (r << 16) | (g << 8) | b))
        } else if (n == 8) {
            let r: UInt32 = SVGParserImpl.hexPair(hex[0], hex[1], original)
            let g: UInt32 = SVGParserImpl.hexPair(hex[2], hex[3], original)
            let b: UInt32 = SVGParserImpl.hexPair(hex[4], hex[5], original)
            let a: UInt32 = SVGParserImpl.hexPair(hex[6], hex[7], original)
            return Colour(SVGParserImpl.colourFromArgb((a << 24) | (r << 16) | (g << 8) | b))
        }
        throw SVGParseException("Invalid colour value: " + original)
    }

    private static func hexPair(hi: UInt8, lo: UInt8, original: String): UInt32 {
        let h: Int64 = SVGParserImpl.hexDigit(hi, original)
        let l: Int64 = SVGParserImpl.hexDigit(lo, original)
        return UInt32(h * 16 + l)
    }

    private static func hexDigit(c: UInt8, original: String): Int64 {
        if (c >= b'0' && c <= b'9') {
            return Int64(c) - Int64(b'0')
        }
        if (c >= b'a' && c <= b'f') {
            return Int64(c) - Int64(b'a') + 10
        }
        if (c >= b'A' && c <= b'F') {
            return Int64(c) - Int64(b'A') + 10
        }
        throw SVGParseException("Invalid colour value: " + original)
    }

    // 取出 func(...) 中括号内的参数文本
    private static func colourFuncArgs(s: String, original: String): String {
        if (let Some(openIdx) <- s.indexOf("(")) {
            if (s.endsWith(")")) {
                return s[(openIdx + 1)..(s.size - 1)].trimAscii()
            }
        }
        throw SVGParseException("Invalid colour value: " + original)
    }

    private static func colourFuncParts(s: String, original: String): Array<String> {
        return SVGParserImpl.colourFuncArgs(s, original).replace(",", " ").replace("/", " ").split(" ",
            removeEmpty: true)
    }

    private static func parseRgbColour(s: String, original: String): Colour {
        let parts: Array<String> = SVGParserImpl.colourFuncParts(s, original)
        if (parts.size < 3) {
            throw SVGParseException("Invalid colour value: " + original)
        }
        let r: UInt32 = SVGParserImpl.colourComponent(parts[0], false, original)
        let g: UInt32 = SVGParserImpl.colourComponent(parts[1], false, original)
        let b: UInt32 = SVGParserImpl.colourComponent(parts[2], false, original)
        var a: UInt32 = 255u32
        if (parts.size >= 4) {
            a = SVGParserImpl.colourComponent(parts[3], true, original)
        }
        return Colour(SVGParserImpl.colourFromArgb((a << 24) | (r << 16) | (g << 8) | b))
    }

    private static func parseHslColour(s: String, original: String): Colour {
        let parts: Array<String> = SVGParserImpl.colourFuncParts(s, original)
        if (parts.size < 3) {
            throw SVGParseException("Invalid colour value: " + original)
        }
        let hue: Float64 = SVGParserImpl.stripDegrees(parts[0], original)
        let sat: Float64 = SVGParserImpl.percentFraction(parts[1], original)
        let light: Float64 = SVGParserImpl.percentFraction(parts[2], original)
        var a: UInt32 = 255u32
        if (parts.size >= 4) {
            a = SVGParserImpl.colourComponent(parts[3], true, original)
        }
        var hueNorm: Float64 = hue
        while (hueNorm < 0.0) {
            hueNorm += 360.0
        }
        while (hueNorm >= 360.0) {
            hueNorm -= 360.0
        }
        let h: Float64 = hueNorm / 60.0
        let s1: Float64 = if (sat < 0.0) {
            0.0
        } else {
            min(sat, 1.0)
        }
        let l1: Float64 = if (light < 0.0) {
            0.0
        } else {
            min(light, 1.0)
        }
        let t2: Float64 = if (l1 <= 0.5) {
            l1 * (s1 + 1.0)
        } else {
            l1 + s1 - (l1 * s1)
        }
        let t1: Float64 = l1 * 2.0 - t2
        let r: UInt32 = SVGParserImpl.clamp255ToByte(SVGParserImpl.hueToRgb(t1, t2, h + 2.0) * 255.0)
        let g: UInt32 = SVGParserImpl.clamp255ToByte(SVGParserImpl.hueToRgb(t1, t2, h) * 255.0)
        let b: UInt32 = SVGParserImpl.clamp255ToByte(SVGParserImpl.hueToRgb(t1, t2, h - 2.0) * 255.0)
        return Colour(SVGParserImpl.colourFromArgb((a << 24) | (r << 16) | (g << 8) | b))
    }

    private static func hueToRgb(t1: Float64, t2: Float64, hue: Float64): Float64 {
        var h: Float64 = hue
        if (h < 0.0) {
            h += 6.0
        }
        if (h >= 6.0) {
            h -= 6.0
        }
        if (h < 1.0) {
            return (t2 - t1) * h + t1
        }
        if (h < 3.0) {
            return t2
        }
        if (h < 4.0) {
            return (t2 - t1) * (4.0 - h) + t1
        }
        return t1
    }

    // 解析 rgb()/hsl() 的单个分量。isAlpha 为 true 时返回 0..255 的 alpha 字节；
    // 否则返回 0..255 的颜色通道字节。
    private static func colourComponent(part: String, isAlpha: Bool, original: String): UInt32 {
        let v: String = part.trimAscii()
        if (v.endsWith("%")) {
            let num: Float64 = SVGParserImpl.safeParseFloat(v[..(v.size - 1)].trimAscii(), original)
            if (isAlpha) {
                return SVGParserImpl.clampUnitToByte(num / 100.0)
            }
            return SVGParserImpl.clamp255ToByte(num * 255.0 / 100.0)
        }
        let num: Float64 = SVGParserImpl.safeParseFloat(v, original)
        if (isAlpha) {
            return SVGParserImpl.clampUnitToByte(num)
        }
        return SVGParserImpl.clamp255ToByte(num)
    }

    private static func percentFraction(part: String, original: String): Float64 {
        let v: String = part.trimAscii()
        if (v.endsWith("%")) {
            return SVGParserImpl.safeParseFloat(v[..(v.size - 1)].trimAscii(), original) / 100.0
        }
        return SVGParserImpl.safeParseFloat(v, original) / 100.0
    }

    private static func stripDegrees(part: String, original: String): Float64 {
        let v: String = part.trimAscii().toAsciiLower()
        if (v.endsWith("deg")) {
            return SVGParserImpl.safeParseFloat(v[..(v.size - 3)].trimAscii(), original)
        }
        return SVGParserImpl.safeParseFloat(v, original)
    }

    private static func safeParseFloat(v: String, original: String): Float64 {
        try {
            return SVGParserImpl.parseFloat(v)
        } catch (e: SVGParseException) {
            throw SVGParseException("Invalid colour value: " + original)
        }
    }

    private static func clamp255ToByte(v: Float64): UInt32 {
        if (v <= 0.0) {
            return 0u32
        }
        if (v >= 255.0) {
            return 255u32
        }
        return UInt32(v + 0.5)
    }

    private static func clampUnitToByte(v: Float64): UInt32 {
        return SVGParserImpl.clamp255ToByte(v * 255.0)
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
        colourKeywords.add("aliceblue", 0xf0f8ff)
        colourKeywords.add("antiquewhite", 0xfaebd7)
        colourKeywords.add("aqua", 0x00ffff)
        colourKeywords.add("aquamarine", 0x7fffd4)
        colourKeywords.add("azure", 0xf0ffff)
        colourKeywords.add("beige", 0xf5f5dc)
        colourKeywords.add("bisque", 0xffe4c4)
        colourKeywords.add("black", 0x000000)
        colourKeywords.add("blanchedalmond", 0xffebcd)
        colourKeywords.add("blue", 0x0000ff)
        colourKeywords.add("blueviolet", 0x8a2be2)
        colourKeywords.add("brown", 0xa52a2a)
        colourKeywords.add("burlywood", 0xdeb887)
        colourKeywords.add("cadetblue", 0x5f9ea0)
        colourKeywords.add("chartreuse", 0x7fff00)
        colourKeywords.add("chocolate", 0xd2691e)
        colourKeywords.add("coral", 0xff7f50)
        colourKeywords.add("cornflowerblue", 0x6495ed)
        colourKeywords.add("cornsilk", 0xfff8dc)
        colourKeywords.add("crimson", 0xdc143c)
        colourKeywords.add("cyan", 0x00ffff)
        colourKeywords.add("darkblue", 0x00008b)
        colourKeywords.add("darkcyan", 0x008b8b)
        colourKeywords.add("darkgoldenrod", 0xb8860b)
        colourKeywords.add("darkgray", 0xa9a9a9)
        colourKeywords.add("darkgreen", 0x006400)
        colourKeywords.add("darkgrey", 0xa9a9a9)
        colourKeywords.add("darkkhaki", 0xbdb76b)
        colourKeywords.add("darkmagenta", 0x8b008b)
        colourKeywords.add("darkolivegreen", 0x556b2f)
        colourKeywords.add("darkorange", 0xff8c00)
        colourKeywords.add("darkorchid", 0x9932cc)
        colourKeywords.add("darkred", 0x8b0000)
        colourKeywords.add("darksalmon", 0xe9967a)
        colourKeywords.add("darkseagreen", 0x8fbc8f)
        colourKeywords.add("darkslateblue", 0x483d8b)
        colourKeywords.add("darkslategray", 0x2f4f4f)
        colourKeywords.add("darkslategrey", 0x2f4f4f)
        colourKeywords.add("darkturquoise", 0x00ced1)
        colourKeywords.add("darkviolet", 0x9400d3)
        colourKeywords.add("deeppink", 0xff1493)
        colourKeywords.add("deepskyblue", 0x00bfff)
        colourKeywords.add("dimgray", 0x696969)
        colourKeywords.add("dimgrey", 0x696969)
        colourKeywords.add("dodgerblue", 0x1e90ff)
        colourKeywords.add("firebrick", 0xb22222)
        colourKeywords.add("floralwhite", 0xfffaf0)
        colourKeywords.add("forestgreen", 0x228b22)
        colourKeywords.add("fuchsia", 0xff00ff)
        colourKeywords.add("gainsboro", 0xdcdcdc)
        colourKeywords.add("ghostwhite", 0xf8f8ff)
        colourKeywords.add("gold", 0xffd700)
        colourKeywords.add("goldenrod", 0xdaa520)
        colourKeywords.add("gray", 0x808080)
        colourKeywords.add("green", 0x008000)
        colourKeywords.add("greenyellow", 0xadff2f)
        colourKeywords.add("grey", 0x808080)
        colourKeywords.add("honeydew", 0xf0fff0)
        colourKeywords.add("hotpink", 0xff69b4)
        colourKeywords.add("indianred", 0xcd5c5c)
        colourKeywords.add("indigo", 0x4b0082)
        colourKeywords.add("ivory", 0xfffff0)
        colourKeywords.add("khaki", 0xf0e68c)
        colourKeywords.add("lavender", 0xe6e6fa)
        colourKeywords.add("lavenderblush", 0xfff0f5)
        colourKeywords.add("lawngreen", 0x7cfc00)
        colourKeywords.add("lemonchiffon", 0xfffacd)
        colourKeywords.add("lightblue", 0xadd8e6)
        colourKeywords.add("lightcoral", 0xf08080)
        colourKeywords.add("lightcyan", 0xe0ffff)
        colourKeywords.add("lightgoldenrodyellow", 0xfafad2)
        colourKeywords.add("lightgray", 0xd3d3d3)
        colourKeywords.add("lightgreen", 0x90ee90)
        colourKeywords.add("lightgrey", 0xd3d3d3)
        colourKeywords.add("lightpink", 0xffb6c1)
        colourKeywords.add("lightsalmon", 0xffa07a)
        colourKeywords.add("lightseagreen", 0x20b2aa)
        colourKeywords.add("lightskyblue", 0x87cefa)
        colourKeywords.add("lightslategray", 0x778899)
        colourKeywords.add("lightslategrey", 0x778899)
        colourKeywords.add("lightsteelblue", 0xb0c4de)
        colourKeywords.add("lightyellow", 0xffffe0)
        colourKeywords.add("lime", 0x00ff00)
        colourKeywords.add("limegreen", 0x32cd32)
        colourKeywords.add("linen", 0xfaf0e6)
        colourKeywords.add("magenta", 0xff00ff)
        colourKeywords.add("maroon", 0x800000)
        colourKeywords.add("mediumaquamarine", 0x66cdaa)
        colourKeywords.add("mediumblue", 0x0000cd)
        colourKeywords.add("mediumorchid", 0xba55d3)
        colourKeywords.add("mediumpurple", 0x9370db)
        colourKeywords.add("mediumseagreen", 0x3cb371)
        colourKeywords.add("mediumslateblue", 0x7b68ee)
        colourKeywords.add("mediumspringgreen", 0x00fa9a)
        colourKeywords.add("mediumturquoise", 0x48d1cc)
        colourKeywords.add("mediumvioletred", 0xc71585)
        colourKeywords.add("midnightblue", 0x191970)
        colourKeywords.add("mintcream", 0xf5fffa)
        colourKeywords.add("mistyrose", 0xffe4e1)
        colourKeywords.add("moccasin", 0xffe4b5)
        colourKeywords.add("navajowhite", 0xffdead)
        colourKeywords.add("navy", 0x000080)
        colourKeywords.add("oldlace", 0xfdf5e6)
        colourKeywords.add("olive", 0x808000)
        colourKeywords.add("olivedrab", 0x6b8e23)
        colourKeywords.add("orange", 0xffa500)
        colourKeywords.add("orangered", 0xff4500)
        colourKeywords.add("orchid", 0xda70d6)
        colourKeywords.add("palegoldenrod", 0xeee8aa)
        colourKeywords.add("palegreen", 0x98fb98)
        colourKeywords.add("paleturquoise", 0xafeeee)
        colourKeywords.add("palevioletred", 0xdb7093)
        colourKeywords.add("papayawhip", 0xffefd5)
        colourKeywords.add("peachpuff", 0xffdab9)
        colourKeywords.add("peru", 0xcd853f)
        colourKeywords.add("pink", 0xffc0cb)
        colourKeywords.add("plum", 0xdda0dd)
        colourKeywords.add("powderblue", 0xb0e0e6)
        colourKeywords.add("purple", 0x800080)
        colourKeywords.add("rebeccapurple", 0x663399)
        colourKeywords.add("red", 0xff0000)
        colourKeywords.add("rosybrown", 0xbc8f8f)
        colourKeywords.add("royalblue", 0x4169e1)
        colourKeywords.add("saddlebrown", 0x8b4513)
        colourKeywords.add("salmon", 0xfa8072)
        colourKeywords.add("sandybrown", 0xf4a460)
        colourKeywords.add("seagreen", 0x2e8b57)
        colourKeywords.add("seashell", 0xfff5ee)
        colourKeywords.add("sienna", 0xa0522d)
        colourKeywords.add("silver", 0xc0c0c0)
        colourKeywords.add("skyblue", 0x87ceeb)
        colourKeywords.add("slateblue", 0x6a5acd)
        colourKeywords.add("slategray", 0x708090)
        colourKeywords.add("slategrey", 0x708090)
        colourKeywords.add("snow", 0xfffafa)
        colourKeywords.add("springgreen", 0x00ff7f)
        colourKeywords.add("steelblue", 0x4682b4)
        colourKeywords.add("tan", 0xd2b48c)
        colourKeywords.add("teal", 0x008080)
        colourKeywords.add("thistle", 0xd8bfd8)
        colourKeywords.add("tomato", 0xff6347)
        colourKeywords.add("turquoise", 0x40e0d0)
        colourKeywords.add("violet", 0xee82ee)
        colourKeywords.add("wheat", 0xf5deb3)
        colourKeywords.add("white", 0xffffff)
        colourKeywords.add("whitesmoke", 0xF5F5F5)
        colourKeywords.add("yellow", 0xffff00)
        colourKeywords.add("yellowgreen", 0x9acd32)
        colourKeywords.add("transparent", 0x000000)
    }
}
