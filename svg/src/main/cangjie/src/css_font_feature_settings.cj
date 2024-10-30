/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

/*
 * Keeps a list of font feature settings and their values.
 */
public class CSSFontFeatureSettings <: Equatable<CSSFontFeatureSettings> {
    static let FONT_VARIANT_NORMAL: String = "normal"
    static let FONT_VARIANT_SMALL_CAPS: String = "small-caps"
    private static let FONT_VARIANT_AUTO: String = "auto"
    private static let FONT_VARIANT_NONE: String = "none"
    private static let FEATURE_ON: String = "on"
    private static let FEATURE_OFF: String = "off"
    private static let VALUE_ON: Int64 = 1
    private static let VALUE_OFF: Int64 = 0
    private static let TOKEN_ERROR: String = "ERR"
    public static let FEATURE_KERN: String = "kern"
    public static let FEATURE_CLIG: String = "clig"
    public static let FEATURE_LIGA: String = "liga"
    public static let FEATURE_DLIG: String = "dlig"
    public static let FEATURE_HLIG: String = "hlig"
    public static let FEATURE_CALT: String = "calt"
    private static let FONT_VARIANT_SUB: String = "sub"
    private static let FONT_VARIANT_SUPER: String = "super"
    private static let FEATURE_SUBS: String = "subs"
    private static let FEATURE_SUPS: String = "sups"
    private static let FONT_VARIANT_COMMON_LIGATURES: String = "common-ligatures"
    private static let FONT_VARIANT_NO_COMMON_LIGATURES: String = "no-common-ligatures"
    private static let FONT_VARIANT_DISCRETIONARY_LIGATURES: String = "discretionary-ligatures"
    private static let FONT_VARIANT_NO_DISCRETIONARY_LIGATURES: String = "no-discretionary-ligatures"
    private static let FONT_VARIANT_HISTORICAL_LIGATURES: String = "historical-ligatures"
    private static let FONT_VARIANT_NO_HISTORICAL_LIGATURES: String = "no-historical-ligatures"
    private static let FONT_VARIANT_CONTEXTUAL_LIGATURES: String = "contextual"
    private static let FONT_VARIANT_NO_CONTEXTUAL_LIGATURES: String = "no-contextual"
    private static let FONT_VARIANT_ALL_SMALL_CAPS: String = "all-small-caps"
    private static let FONT_VARIANT_PETITE_CAPS: String = "petite-caps"
    private static let FONT_VARIANT_ALL_PETITE_CAPS: String = "all-petite-caps"
    private static let FONT_VARIANT_UNICASE: String = "unicase"
    private static let FONT_VARIANT_TITLING_CAPS: String = "titling-caps"
    private static let FEATURE_SMCP: String = "smcp"
    private static let FEATURE_C2SC: String = "c2sc"
    private static let FEATURE_PCAP: String = "pcap"
    private static let FEATURE_C2PC: String = "c2pc"
    private static let FEATURE_UNIC: String = "unic"
    private static let FEATURE_TITL: String = "titl"
    public static let FEATURE_LNUM: String = "lnum"
    public static let FEATURE_ONUM: String = "onum"
    public static let FEATURE_PNUM: String = "pnum"
    public static let FEATURE_TNUM: String = "tnum"
    public static let FEATURE_FRAC: String = "frac"
    public static let FEATURE_AFRC: String = "afrc"
    public static let FEATURE_ORDN: String = "ordn"
    public static let FEATURE_ZERO: String = "zero"
    private static let FONT_VARIANT_JIS78: String = "jis78"
    private static let FONT_VARIANT_JIS83: String = "jis83"
    private static let FONT_VARIANT_JIS90: String = "jis90"
    private static let FONT_VARIANT_JIS04: String = "jis04"
    private static let FONT_VARIANT_SIMPLIFIED: String = "simplified"
    private static let FONT_VARIANT_TRADITIONAL: String = "traditional"
    private static let FONT_VARIANT_FULL_WIDTH: String = "full-width"
    private static let FONT_VARIANT_PROPORTIONAL_WIDTH: String = "proportional-width"
    private static let FONT_VARIANT_RUBY: String = "ruby"
    public static let FEATURE_JP78: String = "jp78"
    public static let FEATURE_JP83: String = "jp83"
    public static let FEATURE_JP90: String = "jp90"
    public static let FEATURE_JP04: String = "jp04"
    public static let FEATURE_SMPL: String = "smpl"
    public static let FEATURE_TRAD: String = "trad"
    public static let FEATURE_FWID: String = "fwid"
    public static let FEATURE_PWID: String = "pwid"
    public static let FEATURE_RUBY: String = "ruby"
    private static let FONT_VARIANT_LINING_NUMS: String = "lining-nums"
    private static let FONT_VARIANT_OLDSTYLE_NUMS: String = "oldstyle-nums"
    private static let FONT_VARIANT_PROPORTIONAL_NUMS: String = "proportional-nums"
    private static let FONT_VARIANT_TABULAR_NUMS: String = "tabular-nums"
    private static let FONT_VARIANT_DIAGONAL_FRACTIONS: String = "diagonal-fractions"
    private static let FONT_VARIANT_STACKED_FRACTIONS: String = "stacked-fractions"
    private static let FONT_VARIANT_ORDINAL: String = "ordinal"
    private static let FONT_VARIANT_SLASHED_ZERO: String = "slashed-zero"
    public static let ERROR: CSSFontFeatureSettings = CSSFontFeatureSettings()
    private static var LIGATURES_ALL_OFF: ?CSSFontFeatureSettings = None
    private static var CAPS_SMALL_CAPS: ?CSSFontFeatureSettings = None
    public static let FONT_FEATURE_SETTINGS_NORMAL: CSSFontFeatureSettings = makeDefaultSettings()
    static var LIGATURES_NORMAL: CSSFontFeatureSettings = {
        =>
        let LIGATURES_NORMAL = CSSFontFeatureSettings()
        LIGATURES_NORMAL.settings.put(FEATURE_LIGA, VALUE_ON)
        LIGATURES_NORMAL.settings.put(FEATURE_CLIG, VALUE_ON)
        LIGATURES_NORMAL.settings.put(FEATURE_DLIG, VALUE_OFF)
        LIGATURES_NORMAL.settings.put(FEATURE_HLIG, VALUE_OFF)
        LIGATURES_NORMAL.settings.put(FEATURE_CALT, VALUE_ON)
        return LIGATURES_NORMAL
    }()

    static var POSITION_ALL_OFF: CSSFontFeatureSettings = {
        =>
        let POSITION_ALL_OFF = CSSFontFeatureSettings()
        POSITION_ALL_OFF.settings.put(FEATURE_SUBS, VALUE_OFF)
        POSITION_ALL_OFF.settings.put(FEATURE_SUPS, VALUE_OFF)
        return POSITION_ALL_OFF
    }()

    static var CAPS_ALL_OFF: CSSFontFeatureSettings = {
        =>
        let CAPS_ALL_OFF = CSSFontFeatureSettings()
        CAPS_ALL_OFF.settings.put(FEATURE_SMCP, VALUE_OFF)
        CAPS_ALL_OFF.settings.put(FEATURE_C2SC, VALUE_OFF)
        CAPS_ALL_OFF.settings.put(FEATURE_PCAP, VALUE_OFF)
        CAPS_ALL_OFF.settings.put(FEATURE_C2PC, VALUE_OFF)
        CAPS_ALL_OFF.settings.put(FEATURE_UNIC, VALUE_OFF)
        CAPS_ALL_OFF.settings.put(FEATURE_TITL, VALUE_OFF)
        return CAPS_ALL_OFF
    }()

    static var NUMERIC_ALL_OFF: CSSFontFeatureSettings = {
        =>
        let NUMERIC_ALL_OFF = CSSFontFeatureSettings()
        NUMERIC_ALL_OFF.settings.put(FEATURE_LNUM, VALUE_OFF)
        NUMERIC_ALL_OFF.settings.put(FEATURE_ONUM, VALUE_OFF)
        NUMERIC_ALL_OFF.settings.put(FEATURE_PNUM, VALUE_OFF)
        NUMERIC_ALL_OFF.settings.put(FEATURE_TNUM, VALUE_OFF)
        NUMERIC_ALL_OFF.settings.put(FEATURE_FRAC, VALUE_OFF)
        NUMERIC_ALL_OFF.settings.put(FEATURE_AFRC, VALUE_OFF)
        NUMERIC_ALL_OFF.settings.put(FEATURE_ORDN, VALUE_OFF)
        NUMERIC_ALL_OFF.settings.put(FEATURE_ZERO, VALUE_OFF)
        return NUMERIC_ALL_OFF
    }()

    static var EAST_ASIAN_ALL_OFF: CSSFontFeatureSettings = {
        =>
        let EAST_ASIAN_ALL_OFF = CSSFontFeatureSettings()
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_JP78, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_JP83, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_JP90, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_JP04, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_SMPL, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_TRAD, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_FWID, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_PWID, VALUE_OFF)
        EAST_ASIAN_ALL_OFF.settings.put(FEATURE_RUBY, VALUE_OFF)
        return EAST_ASIAN_ALL_OFF
    }()

    private var settings: HashMap<String, Int64> = HashMap<String, Int64>()

    public init() {
    }

    init(initialMap: HashMap<String, Int64>) {
        this.settings = initialMap
    }

    init(other: ?CSSFontFeatureSettings) {
        if (let Some(v) <- other) {
            this.settings = HashMap<String, Int64>(v.settings)
        }
    }

    public func applySettings(featureSettings: ?CSSFontFeatureSettings): Unit {
        if (featureSettings.isNone()) {
            return
        }
        this.settings.putAll(featureSettings().settings)
    }

    public func applyKerning(kern: String): Unit {
        if (kern == FontKerning.none) {
            this.settings.put(FEATURE_KERN, VALUE_OFF)
        } else {
            this.settings.put(FEATURE_KERN, VALUE_ON)
        }
    }

    public func hasSettings(): Bool {
        return this.settings.size > 0
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

    static func parseFontFeatureSettings(val: String): CSSFontFeatureSettings {
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings()
        let scan: TextScanner = TextScanner(val)
        scan.skipWhitespace()
        while (true) {
            if (scan.empty()) {
                break
            }
            let entry: FontFeatureEntry = nextFeatureEntry(scan)
            if (entry == FontFeatureEntry()) {
                return CSSFontFeatureSettings()
            }
            result.settings.put(entry.name, entry.val)
            scan.skipCommaWhitespace()
        }
        return result
    }

    private static func nextFeatureEntry(scan: TextScanner): FontFeatureEntry {
        scan.skipWhitespace()
        let name: String = scan.nextQuotedString()
        if (name.size != 4) {
            return FontFeatureEntry()
        }
        scan.skipWhitespace()
        var val: Int64 = 1
        if (!scan.empty()) {
            let num: Int64 = scan.nextInteger(false)
            if (num == 0) {
                if (scan.consume(FEATURE_OFF)) {
                    val = 0
                } else {
                    scan.consume(FEATURE_ON)
                }
            } else if (val > 99) {
                return FontFeatureEntry()
            } else {
                val = num
            }
        }
        return FontFeatureEntry(name, val)
    }

    static func parseFontKerning(val: String): String {
        if (val == FONT_VARIANT_AUTO) {
            return FontKerning.auto
        } else if (val == FONT_VARIANT_NORMAL) {
            return FontKerning.normal
        } else if (val == FONT_VARIANT_NONE) {
            return FontKerning.none
        } else {
            return ""
        }
    }

    private static func extractTokensAsList(val: String): ArrayList<String> {
        let scan: TextScanner = TextScanner(val)
        scan.skipWhitespace()
        if (scan.empty()) {
            return ArrayList<String>()
        }
        let result: ArrayList<String> = ArrayList<String>()
        while (!scan.empty()) {
            result.append(scan.nextToken())
            scan.skipWhitespace()
        }
        return result
    }

    private static func containsWhich(tokens: ArrayList<String>, token1: String, token2: String): Int64 {
        if (removeElement(tokens, token1)) {
            if (tokens.contains(token1) || tokens.contains(token2)) {
                return 3
            } else {
                return 1
            }
        } else if (removeElement(tokens, token2)) {
            if (tokens.contains(token2)) {
                return 3
            }
            return 2
        }
        return 0
    }

    private static func containsOnce(tokens: ArrayList<String>, token1: String): Int64 {
        if (removeElement(tokens, token1)) {
            if (tokens.contains(token1)) {
                return 2
            }
            return 1
        }
        return 0
    }

    static func removeElement(arr: ArrayList<String>, element: String): Bool {
        for (i in 0..arr.size) {
            if (arr[i] == element) {
                arr.remove(i)
                return true
            }
        }
        return false
    }

    private static func containsOneOf(haystack: ArrayList<String>, needles: Array<String>): String {
        var found: String = ""
        for (needle in needles) {
            if (found == "" && removeElement(haystack, needle)) {
                found = needle
            }
            if (haystack.contains(needle)) {
                return TOKEN_ERROR
            }
        }
        return found
    }

    static func parseVariantLigatures(val: String): ?CSSFontFeatureSettings {
        if (val == FONT_VARIANT_NORMAL) {
            return LIGATURES_NORMAL
        } else if (val == FONT_VARIANT_NONE) {
            ensureLigaturesNone()
            return LIGATURES_ALL_OFF
        }
        let tokens: ArrayList<String> = extractTokensAsList(val)
        if (tokens.isEmpty()) {
            return None
        }
        ensureLigaturesNone()
        let result: ?CSSFontFeatureSettings = parseVariantLigaturesSpecial(tokens)
        if (result.isNone() || result() == ERROR || tokens.size > 0) {
            return None
        }
        return result
    }

    private static func parseVariantLigaturesSpecial(tokens: ArrayList<String>): ?CSSFontFeatureSettings {
        ensureLigaturesNone()
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings(LIGATURES_ALL_OFF)
        var found: Bool = false
        match (containsWhich(tokens, FONT_VARIANT_COMMON_LIGATURES, FONT_VARIANT_NO_COMMON_LIGATURES)) {
            case 1 =>
                result.addSettings(FEATURE_CLIG, FEATURE_LIGA, VALUE_ON)
                found = true
            case 2 =>
                result.addSettings(FEATURE_CLIG, FEATURE_LIGA, VALUE_OFF)
                found = true
            case 3 => return ERROR
            case _ => ()
        }

        match (containsWhich(tokens, FONT_VARIANT_DISCRETIONARY_LIGATURES, FONT_VARIANT_NO_DISCRETIONARY_LIGATURES)) {
            case 1 =>
                result.settings.put(FEATURE_DLIG, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_DLIG, VALUE_OFF)
                found = true
            case 3 => return ERROR

            case _ => ()
        }

        match (containsWhich(tokens, FONT_VARIANT_HISTORICAL_LIGATURES, FONT_VARIANT_NO_HISTORICAL_LIGATURES)) {
            case 1 =>
                result.settings.put(FEATURE_HLIG, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_HLIG, VALUE_OFF)
                found = true
            case 3 => return ERROR
            case _ => ()
        }

        match (containsWhich(tokens, FONT_VARIANT_CONTEXTUAL_LIGATURES, FONT_VARIANT_NO_CONTEXTUAL_LIGATURES)) {
            case 1 =>
                result.settings.put(FEATURE_CALT, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_CALT, VALUE_OFF)
                found = true
            case 3 => return ERROR
            case _ => ()
        }

        if (found) {
            return result
        } else {
            return CSSFontFeatureSettings()
        }
    }

    private func addSettings(feature1: String, feature2: String, onOrOff: Int64): Unit {
        this.settings.put(feature1, onOrOff)
        this.settings.put(feature2, onOrOff)
    }

    static func parseVariantPosition(val: String): CSSFontFeatureSettings {
        if (val == FONT_VARIANT_NORMAL) {
            return POSITION_ALL_OFF
        }
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings(POSITION_ALL_OFF)
        match (val) {
            case FONT_VARIANT_SUB => result.settings.put(FEATURE_SUBS, VALUE_ON)
            case FONT_VARIANT_SUPER => result.settings.put(FEATURE_SUPS, VALUE_ON)
            case _ => return CSSFontFeatureSettings()
        }
        return result
    }

    private static func parseVariantPositionSpecial(tokens: ArrayList<String>): ?CSSFontFeatureSettings {
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings(POSITION_ALL_OFF)
        var found: Bool = false
        match (containsWhich(tokens, FONT_VARIANT_SUB, FONT_VARIANT_SUPER)) {
            case 1 =>
                result.settings.put(FEATURE_SUBS, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_SUPS, VALUE_ON)
                found = true
            case 3 => return ERROR
            case _ => ()
        }
        if (found) {
            return result
        }
        return None
    }

    static func parseVariantCaps(val: String): ?CSSFontFeatureSettings {
        if (val == FONT_VARIANT_NORMAL) {
            return CAPS_ALL_OFF
        }
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings(CAPS_ALL_OFF)
        if (setCapsFeature(result, val)) {
            return result
        }
        return None
    }

    private static func setCapsFeature(result: CSSFontFeatureSettings, val: String): Bool {
        match (val) {
            case FONT_VARIANT_SMALL_CAPS => result.settings.put(FEATURE_SMCP, VALUE_ON)
            case FONT_VARIANT_ALL_SMALL_CAPS => result.addSettings(FEATURE_SMCP, FEATURE_C2SC, VALUE_ON)
            case FONT_VARIANT_PETITE_CAPS => result.settings.put(FEATURE_PCAP, VALUE_ON)
            case FONT_VARIANT_ALL_PETITE_CAPS => result.addSettings(FEATURE_PCAP, FEATURE_C2PC, VALUE_ON)
            case FONT_VARIANT_UNICASE => result.settings.put(FEATURE_UNIC, VALUE_ON)
            case FONT_VARIANT_TITLING_CAPS => result.settings.put(FEATURE_TITL, VALUE_ON)
            case _ => return false
        }
        return true
    }

    private static func parseVariantCapsSpecial(tokens: ArrayList<String>): CSSFontFeatureSettings {
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings(CAPS_ALL_OFF)
        let which: String = containsOneOf(tokens, FONT_VARIANT_SMALL_CAPS, FONT_VARIANT_ALL_SMALL_CAPS,
            FONT_VARIANT_PETITE_CAPS, FONT_VARIANT_ALL_PETITE_CAPS, FONT_VARIANT_UNICASE, FONT_VARIANT_TITLING_CAPS)
        if (which == TOKEN_ERROR) {
            return ERROR
        }
        setCapsFeature(result, which)
        return result
    }

    static func parseVariantNumeric(val: String): ?CSSFontFeatureSettings {
        if (val == FONT_VARIANT_NORMAL) {
            return NUMERIC_ALL_OFF
        }
        let tokens: ArrayList<String> = extractTokensAsList(val)
        if (tokens.isEmpty()) {
            return None
        }
        let result: ?CSSFontFeatureSettings = parseVariantNumericSpecial(tokens)
        if (result.isNone() || result() == ERROR || tokens.size > 0) {
            return None
        }
        return result
    }

    private static func parseVariantNumericSpecial(tokens: ArrayList<String>): ?CSSFontFeatureSettings {
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings(NUMERIC_ALL_OFF)
        var found: Bool = false
        match (containsWhich(tokens, FONT_VARIANT_LINING_NUMS, FONT_VARIANT_OLDSTYLE_NUMS)) {
            case 1 =>
                result.settings.put(FEATURE_LNUM, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_ONUM, VALUE_ON)
                found = true
            case 3 => return ERROR
            case _ => ()
        }
        match (containsWhich(tokens, FONT_VARIANT_PROPORTIONAL_NUMS, FONT_VARIANT_TABULAR_NUMS)) {
            case 1 =>
                result.settings.put(FEATURE_PNUM, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_PNUM, VALUE_ON)
                found = true
            case 3 => return ERROR
            case _ => ()
        }
        match (containsWhich(tokens, FONT_VARIANT_DIAGONAL_FRACTIONS, FONT_VARIANT_STACKED_FRACTIONS)) {
            case 1 =>
                result.settings.put(FEATURE_FRAC, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_FRAC, VALUE_ON)
                found = true
            case 3 => return ERROR
            case _ => ()
        }
        match (containsOnce(tokens, FONT_VARIANT_ORDINAL)) {
            case 1 =>
                result.settings.put(FEATURE_ORDN, VALUE_ON)
                found = true
            case 2 => return ERROR
            case _ => ()
        }
        match (containsOnce(tokens, FONT_VARIANT_SLASHED_ZERO)) {
            case 1 =>
                result.settings.put(FEATURE_ZERO, VALUE_ON)
                found = true
            case 2 => return ERROR
            case _ => ()
        }
        if (found) {
            return result
        } else {
            return None
        }
    }

    static func parseEastAsian(val: String): ?CSSFontFeatureSettings {
        if (val == FONT_VARIANT_NORMAL) {
            return EAST_ASIAN_ALL_OFF
        }
        let tokens: ArrayList<String> = extractTokensAsList(val)
        if (tokens.isEmpty()) {
            return None
        }
        let result: ?CSSFontFeatureSettings = parseVariantEastAsianSpecial(tokens)
        if (result.isNone() || result() == ERROR || tokens.size > 0) {
            return None
        }
        return result
    }

    private static func parseVariantEastAsianSpecial(tokens: ArrayList<String>): ?CSSFontFeatureSettings {
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings(EAST_ASIAN_ALL_OFF)
        var found: Bool = false
        let which: String = containsOneOf(tokens, FONT_VARIANT_JIS78, FONT_VARIANT_JIS83, FONT_VARIANT_JIS90,
            FONT_VARIANT_JIS04, FONT_VARIANT_SIMPLIFIED, FONT_VARIANT_TRADITIONAL)
        match (which) {
            case FONT_VARIANT_JIS78 => result.settings.put(FEATURE_JP78, VALUE_ON)
            case FONT_VARIANT_JIS83 => result.settings.put(FEATURE_JP83, VALUE_ON)
            case FONT_VARIANT_JIS90 => result.settings.put(FEATURE_JP90, VALUE_ON)
            case FONT_VARIANT_JIS04 => result.settings.put(FEATURE_JP04, VALUE_ON)
            case FONT_VARIANT_SIMPLIFIED => result.settings.put(FEATURE_SMPL, VALUE_ON)
            case FONT_VARIANT_TRADITIONAL => result.settings.put(FEATURE_TRAD, VALUE_ON)
            case TOKEN_ERROR => return ERROR
        }
        found = true
        match (containsWhich(tokens, FONT_VARIANT_FULL_WIDTH, FONT_VARIANT_PROPORTIONAL_WIDTH)) {
            case 1 =>
                result.settings.put(FEATURE_FWID, VALUE_ON)
                found = true
            case 2 =>
                result.settings.put(FEATURE_PWID, VALUE_ON)
                found = true
            case 3 => return ERROR
            case _ => ()
        }
        match (containsOnce(tokens, FONT_VARIANT_RUBY)) {
            case 1 =>
                result.settings.put(FEATURE_RUBY, VALUE_ON)
                found = true
            case 2 => return ERROR
            case _ => ()
        }
        if (found) {
            return result
        } else {
            return None
        }
    }

    static func parseFontVariant(style: Style, val: String): Unit {
        if (val == FONT_VARIANT_NORMAL) {
            style.fontVariantLigatures = LIGATURES_NORMAL
            style.fontVariantPosition = POSITION_ALL_OFF
            style.fontVariantCaps = CAPS_ALL_OFF
            style.fontVariantNumeric = NUMERIC_ALL_OFF
            style.fontVariantEastAsian = EAST_ASIAN_ALL_OFF
            style.specifiedFlags |= (Style.SPECIFIED_FONT_VARIANT_LIGATURES | Style.SPECIFIED_FONT_VARIANT_POSITION |
                Style.SPECIFIED_FONT_VARIANT_CAPS | Style.SPECIFIED_FONT_VARIANT_NUMERIC | Style.
                SPECIFIED_FONT_VARIANT_EAST_ASIAN)
            return
        } else if (val == FONT_VARIANT_NONE) {
            ensureLigaturesNone()
            style.fontVariantLigatures = LIGATURES_ALL_OFF
            style.fontVariantPosition = POSITION_ALL_OFF
            style.fontVariantCaps = CAPS_ALL_OFF
            style.fontVariantNumeric = NUMERIC_ALL_OFF
            style.fontVariantEastAsian = EAST_ASIAN_ALL_OFF
            style.specifiedFlags |= (Style.SPECIFIED_FONT_VARIANT_LIGATURES | Style.SPECIFIED_FONT_VARIANT_POSITION |
                Style.SPECIFIED_FONT_VARIANT_CAPS | Style.SPECIFIED_FONT_VARIANT_NUMERIC | Style.
                SPECIFIED_FONT_VARIANT_EAST_ASIAN)
            return
        }
        let tokens: ArrayList<String> = extractTokensAsList(val)
        if (tokens.isEmpty()) {
            return
        }
        let ligatures: ?CSSFontFeatureSettings = parseVariantLigaturesSpecial(tokens)
        if (let Some(v) <- ligatures) {
            if (v == ERROR) {
                return
            }
        }
        var position: ?CSSFontFeatureSettings = None
        if (tokens.size > 0) {
            position = parseVariantPositionSpecial(tokens)
            if (let Some(v) <- position) {
                if (v == ERROR) {
                    return
                }
            }
        }
        var caps: ?CSSFontFeatureSettings = None
        if (tokens.size > 0) {
            caps = parseVariantCapsSpecial(tokens)
            if (caps() == ERROR) {
                return
            }
        }
        var numeric: ?CSSFontFeatureSettings = None
        if (tokens.size > 0) {
            numeric = parseVariantNumericSpecial(tokens)
            if (let Some(v) <- numeric) {
                if (v == ERROR) {
                    return
                }
            }
        }
        var eastAsian: ?CSSFontFeatureSettings = None
        if (tokens.size > 0) {
            eastAsian = parseVariantEastAsianSpecial(tokens)
            if (let Some(v) <- eastAsian) {
                if (v == ERROR) {
                    return
                }
            }
        }
        if (ligatures.isSome()) {
            style.fontVariantLigatures = ligatures
            style.specifiedFlags |= Style.SPECIFIED_FONT_VARIANT_LIGATURES
        }

        if (position.isSome()) {
            style.fontVariantPosition = position
            style.specifiedFlags |= Style.SPECIFIED_FONT_VARIANT_POSITION
        }

        if (caps.isSome()) {
            style.fontVariantCaps = caps
            style.specifiedFlags |= Style.SPECIFIED_FONT_VARIANT_CAPS
        }

        if (numeric.isSome()) {
            style.fontVariantNumeric = numeric
            style.specifiedFlags |= Style.SPECIFIED_FONT_VARIANT_NUMERIC
        }

        if (eastAsian.isSome()) {
            style.fontVariantEastAsian = eastAsian
            style.specifiedFlags |= Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN
        }
    }

    static func makeDefaultSettings(): CSSFontFeatureSettings {
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings()
        result.settings.put("rlig", 1)
        result.settings.put(FEATURE_LIGA, 1)
        result.settings.put(FEATURE_CLIG, 1)
        result.settings.put(FEATURE_CALT, 1)
        result.settings.put("locl", 1)
        result.settings.put("ccmp", 1)
        result.settings.put("mark", 1)
        result.settings.put("mkmk", 1)
        return result
    }

    private static func ensureLigaturesNone(): Unit {
        if (LIGATURES_ALL_OFF.isSome()) {
            return
        }
        let result: CSSFontFeatureSettings = CSSFontFeatureSettings()
        result.settings.put(FEATURE_LIGA, VALUE_OFF)
        result.settings.put(FEATURE_CLIG, VALUE_OFF)
        result.settings.put(FEATURE_DLIG, VALUE_OFF)
        result.settings.put(FEATURE_HLIG, VALUE_OFF)
        result.settings.put(FEATURE_CALT, VALUE_OFF)
        LIGATURES_ALL_OFF = result
    }

    private func ensurePositionNormal(): Unit {
        if (POSITION_ALL_OFF == CSSFontFeatureSettings()) {
            let result: CSSFontFeatureSettings = CSSFontFeatureSettings()
            result.settings.put(FEATURE_SUBS, VALUE_OFF)
            result.settings.put(FEATURE_SUPS, VALUE_OFF)
            POSITION_ALL_OFF = result
        }
    }

    static func makeSmallCaps(): CSSFontFeatureSettings {
        if (let Some(v) <- CAPS_SMALL_CAPS) {
            v
        } else {
            let v = CSSFontFeatureSettings()
            CAPS_SMALL_CAPS = v
            v.settings.put(FEATURE_SMCP, VALUE_ON)
            v.settings.put(FEATURE_C2SC, VALUE_OFF)
            v.settings.put(FEATURE_PCAP, VALUE_OFF)
            v.settings.put(FEATURE_C2PC, VALUE_OFF)
            v.settings.put(FEATURE_UNIC, VALUE_OFF)
            v.settings.put(FEATURE_TITL, VALUE_OFF)
            v
        }
    }

    public operator func ==(that: CSSFontFeatureSettings): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: CSSFontFeatureSettings): Bool {
        return !refEq(this, that)
    }
}

class FontFeatureEntry <: Equatable<FontFeatureEntry> {
    var name: String = ""
    var val: Int64 = 0

    init() {}

    init(name: String, val: Int64) {
        this.name = name
        this.val = val
    }

    public operator func ==(other: FontFeatureEntry): Bool {
        return this.name == other.name && this.val == other.val
    }

    public operator func !=(other: FontFeatureEntry): Bool {
        return !(this == other)
    }
}
