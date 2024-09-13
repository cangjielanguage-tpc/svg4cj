/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

class SimpleAssetResolver <: SVGExternalFileResolver {
    private var assetManager: Object

    private var supportedFormats: ArrayList<String> = ArrayList<String>()

    public init(assetManager: Object) {
        super()
        this.assetManager = assetManager
    }

    public func resolveFont(fontFamily: String, fontWeight: Float64, fontStyle: String, fontStretch: Float64): Object {
        return Object()
    }

    public func resolveImage(filename: String): Object {
        AppLog.info("SimpleAssetResolver resolveImage(" + filename + ")")
        return Object()
    }

    public func isFormatSupported(mimeType: String): Bool {
        if (let Some(v) <- this.supportedFormats.toArray().indexOf(mimeType)) {
            if (v >= 0) {
                return true
            }
        }
        return false
    }

    public func resolveCSSStyleSheet(url: String): String {
        AppLog.info("SimpleAssetResolver resolveCSSStyleSheet(" + url + ")")
        return getAssetAsString(url)
    }

    private func getAssetAsString(url: String): String {
        return ""
    }
}
