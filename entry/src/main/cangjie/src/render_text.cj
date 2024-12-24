/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*

@Entry
@Component
class RenderText {
    var model: SVGImageViewModel = SVGImageViewModel()
    @State
    var flag: Bool = false

    protected override func aboutToAppear() {
        this.model.setImageRawfile("Svg_text.svg", globalAbilityContext)
    }

    func build() {
        Column {
            SVGImageView(model: this.model)
        }
    }
}
