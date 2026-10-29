/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*
internal import ohos.resource_manager.AppResource as OhosResource
import ohos.concurrency.*

@Entry
@Component
class SetSvgSample {
    @State var model: SVGImageViewModel = SVGImageViewModel()

    func build() {
        Stack() {
            SVGImageView(model: getData())
        }
        .height(100.percent)
        .padding(top: 40)
        .margin(bottom: 20)
    }

    public func getData(): SVGImageViewModel {
        let resourceManager = ResourceManager.getResourceManager(getStageContext(globalAbilityContext.getOrThrow()))
        let value: Array<UInt8> = resourceManager.getRawFileContent("box.svg")
        let data = String.fromUtf8(value)
        SVG.getFromString(
            data,
            {
                svg => launch {
                    this.model.setSVG(svg, globalAbilityContext)
                }
            }
        )
        return this.model
    }
}
