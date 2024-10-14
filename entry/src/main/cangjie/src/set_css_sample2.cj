/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*
internal import ohos.resource_manager.Resource as OhosResource

@Entry
@Component
class SetCssSample2 {
    var model: SVGImageViewModel = SVGImageViewModel()
    @State
    var flag: Bool = false

    protected override func aboutToAppear() {
        this.model.setImageRawfile("peach.svg", globalAbilityContext)
    }

    func build() {
        Column {
            Stack() {
                SVGImageView(model: this.model)
            }
            Button("Image渲染测试").onClick(
                {
                    =>
                    flag = !flag
                    if (flag) {
                        this.model.setCSS(".peach { stroke: #00ff00; stroke-width: 6.0; }", globalAbilityContext)
                    } else {
                        this.model.setCSS(".peach { stroke: #ff0000; stroke-width: 6.0; }", globalAbilityContext)
                    }
                }
            )
        }.width(50.percent).height(70.percent).backgroundColor(Color.WHITE)
    }
}
