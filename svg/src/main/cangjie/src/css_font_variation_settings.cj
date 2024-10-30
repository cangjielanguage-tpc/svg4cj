/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

public class CSSFontVariationSettings {
    private var settings: HashMap<String, Float64>

    private static let NORMAL: String = "normal"

    static let VARIATION_WEIGHT: String = "wght"
    static let VARIATION_ITALIC: String = "ital"
    static let VARIATION_OBLIQUE: String = "slnt"
    static let VARIATION_WIDTH: String = "wdth"

    static let VARIATION_ITALIC_VALUE_ON: Float64 = 1.0
    static let VARIATION_OBLIQUE_VALUE_ON: Float64 = -14.0

    public init() {
        this.settings = HashMap<String, Float64>()
    }

    init(initialMap: HashMap<String, Float64>) {
        this.settings = initialMap
    }

    public init(other: CSSFontVariationSettings) {
        this.settings = HashMap<String, Float64>(other.settings)
    }

    public func addSetting(key: String, value: Float64): Unit {
        this.settings.put(key, value)
    }

    public func applySettings(variationSet: ?CSSFontVariationSettings): Unit {
        if (variationSet.isNone()) {
            return
        }
        this.settings.putAll(variationSet().settings)
    }

    public func toString(): String {
        let sb: StringBuilder = StringBuilder()
        for ((k, v) in this.settings) {
            if (sb.size > 0) {
                sb.append(',')
            }
            sb.append("'")
            sb.append(k)
            sb.append("' ")
            sb.append(v)
        }
        return sb.toString()
    }

    static func parseFontVariationSettings(val: String): CSSFontVariationSettings {
        let result: CSSFontVariationSettings = CSSFontVariationSettings()

        let scan: TextScanner = TextScanner(val)
        scan.skipWhitespace()

        if (scan.consume(NORMAL)) {
            return CSSFontVariationSettings()
        }
        while (true) {
            if (scan.empty()) {
                break
            }
            let entry: FontVariationEntry = nextFeatureEntry(scan)
            if (entry == FontVariationEntry()) {
                return CSSFontVariationSettings()
            }
            result.settings.put(entry.name, entry.val)
            scan.skipCommaWhitespace()
        }
        return result
    }

    private static func nextFeatureEntry(scan: TextScanner): FontVariationEntry {
        scan.skipWhitespace()
        let name: String = scan.nextQuotedString()
        if (name == "" || name.size != 4) {
            return FontVariationEntry()
        }

        scan.skipWhitespace()
        if (scan.empty()) {
            return FontVariationEntry()
        }
        let num: Float64 = scan.nextFloat()
        if (num == 0.0) {
            return FontVariationEntry()
        }
        return FontVariationEntry(name, num)
    }
}

class FontVariationEntry <: Equatable<FontVariationEntry> {
    var name: String = ""
    var val: Float64 = 0.0

    init() {}

    public init(name: String, val: Float64) {
        this.name = name
        this.val = val
    }

    public operator func ==(other: FontVariationEntry): Bool {
        return this.name == other.name && this.val == other.val
    }

    public operator func !=(other: FontVariationEntry): Bool {
        return !(this == other)
    }
}
