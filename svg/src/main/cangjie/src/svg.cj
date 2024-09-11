/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class SVG {
    var base: SVGBase

    init(base: SVGBase) {
        this.base = base
    }

    public static func getFromString(svg: String): SVG {
        return SVG(SVGBase.getFromString(svg))
    }

    public static func getFromResource(media: OhosResource, callback: (SVG) -> Unit, abilityContext: AbilityContext): Unit {
        SVGBase.getFromResource(media, {
            v: SVGBase =>
            var svg: SVG = SVG(v)
            callback(svg)
        }, abilityContext)
    }

    public static func getFromRawfile(rawfileName: String, callback: (SVG) -> Unit, abilityContext: AbilityContext): Unit {
        SVGBase.getFromRawfile(rawfileName, {
            v: SVGBase =>
            var svg: SVG = SVG(v)
            callback(svg)
        }, abilityContext)
    }

    func getRootElement(): Svg {
        return base.getRootElement()
    }
}
