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
    private var enableInternalEntities: Bool = true

    private var externalFileResolver: ?SVGExternalFileResolver = None

    public func parseString(str: String): SVGBase {
        return SVGBase(false, SVGExternalFileResolver())
    }

    public func setInternalEntitiesEnabled(enable: Bool): SVGParser {
        this.enableInternalEntities = enable
        return this
    }

    public func setExternalFileResolver(fileResolver: SVGExternalFileResolver): SVGParser {
        this.externalFileResolver = fileResolver
        return this
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
}
