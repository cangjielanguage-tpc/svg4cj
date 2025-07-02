/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package svg

import ohos.state_manage.*
import ohos.state_macro_manage.*
import ohos.hybrid_base.HybridComponentBase
import ohos.component.*
import ohos.base.*
import ohos.ark_interop.*
import ohos.ark_interop_helper.*
import ohos.ark_interop_macro.*
import ohos.ability.*
import ohos.hybrid_base.CJPageEntry
import ohos.concurrency.launch

@Component
class CJSVGImageView {

    @State
    var cssValue: String = ""

    var cjmodel: ?CJSVGImageViewModel

    protected override func aboutToAppear() {
        if (let Some(v) <- cjmodel) {
            if (!v.filename.isEmpty()) {
                v.model.setImageRawfile(v.filename, GlobalContext.getContext())
            } else if (!v.data.isEmpty()) {
                v.model.setFromString(v.data, GlobalContext.getContext())
            } else if (let Some(j) <- imageResource) {
                v.model.setImageResource(j, GlobalContext.getContext())
            }
        }
    }

    public func updateCssValue(cssValue: String) {
        this.cjmodel.getOrThrow().model.setCSS(cssValue, GlobalContext.getContext())
    }

    func build() {
        Column() {
            SVGImageView(model: this.cjmodel.getOrThrow().model)
        }
    }
}

@Interop[ArkTS]
public class CJSVGImageViewModel {
    var filename: String = ""
    var data: String = ""
    var cssValue: String = ""
    var pixelmapValue: ?Array<Byte> = None
    var pixelMapWidth: Int32 = 0
    var pixelMapHeight: Int32 = 0
    var model: SVGImageViewModel = SVGImageViewModel()
    public init() {}

    public func setImageRawfile(filename: String): Unit {
        this.filename = filename
    }

    public func setFromString(data: String): Unit {
        this.data = data
    }

    public func setCSS(cssValue: String): Unit {
        this.cssValue = cssValue
    }

    public func getSVGPixelMap(pixelmapValue: Array<Byte>): Unit {
        let pixelMap = this.model.getSVGPixelMap(pixelmapValue, GlobalContext.getContext())
        this.pixelMapWidth = pixelMap.getImageInfo().size.width
        this.pixelMapHeight = pixelMap.getImageInfo().size.height
        let arr: Array<Byte> = Array<Byte>(Int64(pixelMap.getPixelBytesNumber()), repeat: 0)
        pixelMap.readPixelsToBuffer(arr)
        this.pixelmapValue = arr
    }

    public func getPixelmapValue(): Array<Byte> {
        return if (let Some(v) <- this.pixelmapValue) {
        	v
        } else {
            []
        }
    }

    public func getPixelMapWidth(): Int32 {
        return this.pixelMapWidth
    }

    public func getPixelMapHeight(): Int32 {
        return this.pixelMapHeight
    }
}