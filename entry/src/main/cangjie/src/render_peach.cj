/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*

@Entry
@Component
class RenderPeach {
    var model: SVGImageViewModel = SVGImageViewModel()
    @State
    var flag: Bool = false

    protected override func aboutToAppear() {
        this.model.setImageRawfile("peach.svg", globalAbilityContext)
    }

    func build() {
        Column {
            SVGImageView(model: this.model)
        }.width(50.percent).height(70.percent).backgroundColor(Color.WHITE)
    }
}
