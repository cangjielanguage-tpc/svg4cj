/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class SVG {
    var base: SVGBase

    init(base: SVGBase) {
        this.base = base
    }

    public static func getFromString(data: String, callback: (SVG) -> Unit): Future<Unit> {
        let fut: Future<Unit> = spawn {
            let svgBase: SVGBase = SVGBase.getFromString(data)
            var svg: SVG = SVG(svgBase)
            callback(svg)
        }
        return fut
    }

    public static func getFromResource(media: OhosResource, callback: (SVG) -> Unit, abilityContext: AbilityContext): Future<Unit> {
        let fut: Future<Unit> = spawn {
            SVGBase.getFromResource(
                media,
                {
                    v: SVGBase =>
                    var svg: SVG = SVG(v)
                    callback(svg)
                },
                abilityContext
            )
        }
        return fut
    }

    public static func getFromRawfile(rawfileName: String, callback: (SVG) -> Unit, abilityContext: AbilityContext): Future<Unit> {
        let fut: Future<Unit> = spawn {
            SVGBase.getFromRawfile(
                rawfileName,
                {
                    v: SVGBase =>
                    var svg: SVG = SVG(v)
                    callback(svg)
                },
                abilityContext
            )
        }
        return fut
    }

    func getRootElement(): Svg {
        return base.getRootElement()
    }
}
