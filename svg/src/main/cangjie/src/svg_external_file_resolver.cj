/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public open class SVGExternalFileResolver {

  public open func resolveFont(fontFamily: String, fontWeight: Float64, fontStyle: String, fontStretch: Float64): ?Object {
    return None
  }

  public open func resolveImage(filename: String): ?Object {
    return None
  }

  public open func resolveCSSStyleSheet(url: String): String {
    return ""
  }

  public open func isFormatSupported(mimeType: String): Bool {
    return false
  }
}