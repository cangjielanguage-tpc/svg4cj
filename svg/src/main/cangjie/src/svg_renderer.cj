/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

class SVGRenderer {
    private let state: RendererState = RendererState()
    private var dpi: Float64
    private var document: ?SVGBase = None
    private var externalFileResolver: SVGExternalFileResolver
    private static let BEZIER_ARC_FACTOR: Float64 = 0.5522847498
    public static let LUMINANCE_TO_ALPHA_RED: Float64 = 0.2127
    public static let LUMINANCE_TO_ALPHA_GREEN: Float64 = 0.7151
    public static let LUMINANCE_TO_ALPHA_BLUE: Float64 = 0.0722
    private var combinedPath: Path2D = Path2D()

    func getCurrentFontSize(): Float64 {
        return this.state.fillPaint.getFontSize().value
    }

    init(defaultDPI: Float64, externalFileResolver: SVGExternalFileResolver) {
        this.dpi = defaultDPI
        this.externalFileResolver = externalFileResolver
    }

    func getCurrentFontXHeight(): Float64 {
        let value: Length = this.state.fillPaint.getFontSize()
        return this.state.fillPaint.getFontSize().value / 2.0
    }

    func getDPI(): Float64 {
        return this.dpi
    }

    func getCurrentViewPortInUserUnits(): ?Box {
        if (this.state.viewBox.isSome()) {
            return this.state.viewBox.getOrThrow()
        } else {
            return this.state.viewPort
        }
    }
}

class RendererState {
    var viewPort: ?Box = None
    var viewBox: ?Box = None
    var fillPaint: Paint = Paint()
}
