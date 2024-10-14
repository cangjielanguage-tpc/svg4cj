/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*
internal import ohos.resource_manager.Resource as OhosResource

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
        let value: Array<UInt8> = resourceManager.getRawFileContent("circle.svg")
        let data = String.fromUtf8(value)
        var svg = SVG.getFromString(data)
        this.model.setSVG(svg, globalAbilityContext)
        return this.model
    }

}
