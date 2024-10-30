/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

public struct Alignment {
    public static let none: String = "none"
    public static let xMinYMin: String = "xMinYMin"
    public static let xMidYMin: String = "xMidYMin"
    public static let xMaxYMin: String = "xMaxYMin"
    public static let xMinYMid: String = "xMinYMid"
    public static let xMidYMid: String = "xMidYMid"
    public static let xMaxYMid: String = "xMaxYMid"
    public static let xMinYMax: String = "xMinYMax"
    public static let xMidYMax: String = "xMidYMax"
    public static let xMaxYMax: String = "xMaxYMax"
}

struct Scale {
    public static let meet: String = "meet"
    public static let slice: String = "slice"
}

public class PreserveAspectRatio {
    var alignment: String = ""
    var scale: String = ""
    static let aspectRatioKeywords: HashMap<String, String> = HashMap<String, String>()

    init() {}

    init(alignment: String, scale: String) {
        this.alignment = alignment
        this.scale = scale
    }

    static init() {
        aspectRatioKeywords.put("none", Alignment.none)
        aspectRatioKeywords.put("xMinYMin", Alignment.xMinYMin)
        aspectRatioKeywords.put("xMidYMin", Alignment.xMidYMin)
        aspectRatioKeywords.put("xMaxYMin", Alignment.xMaxYMin)
        aspectRatioKeywords.put("xMinYMid", Alignment.xMinYMid)
        aspectRatioKeywords.put("xMidYMid", Alignment.xMidYMid)
        aspectRatioKeywords.put("xMaxYMid", Alignment.xMaxYMid)
        aspectRatioKeywords.put("xMinYMax", Alignment.xMinYMax)
        aspectRatioKeywords.put("xMidYMax", Alignment.xMidYMax)
        aspectRatioKeywords.put("xMaxYMax", Alignment.xMaxYMax)
    }

    static let UNSCALED: PreserveAspectRatio = PreserveAspectRatio()
    static let STRETCH: PreserveAspectRatio = PreserveAspectRatio()
    static let LETTERBOX: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMid, Scale.meet)
    static let START: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMinYMin, Scale.meet)
    static let END: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMaxYMax, Scale.meet)
    static let TOP: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMin, Scale.meet)
    static let BOTTOM: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMax, Scale.meet)
    static let FULLSCREEN: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMid, Scale.slice)
    static let FULLSCREEN_START: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMinYMin, Scale.slice)

    static func of(value: String): PreserveAspectRatio {
        return parsePreserveAspectRatio(value)
    }

    func getAlignment(): String {
        return this.alignment
    }

    public func getScale(): String {
        return this.scale
    }

    static func parsePreserveAspectRatio(val: String): PreserveAspectRatio {
        return PreserveAspectRatio("align", "scale")
    }

    public operator func ==(that: PreserveAspectRatio): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: PreserveAspectRatio): Bool {
        return !refEq(this, that)
    }
}
