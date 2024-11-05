/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*

@Entry
@Component
class RenderAbstract {
    var model: SVGImageViewModel = SVGImageViewModel()
    @State
    var flag: Bool = false

    protected override func aboutToAppear() {
        this.model.setImageRawfile("abstract.svg", globalAbilityContext)
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
                        this.model.setCSS("#path972 {stroke:" + "red" + ";}", globalAbilityContext)
                    } else {
                        this.model.setCSS("#path972 {stroke:" + "green" + ";}", globalAbilityContext)
                    }
                }
            )
        }.width(100.percent).height(70.percent).backgroundColor(Color.WHITE)
    }
}
