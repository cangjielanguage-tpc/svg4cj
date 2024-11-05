/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*

@Entry
@Component
class RenderAbstract {
    var model: SVGImageViewModel = SVGImageViewModel()

protected override func aboutToAppear() {
    this.model.setImageRawfile("abstract.svg", globalAbilityContext)
}

func build() {
    Column {
        Stack() {
            SVGImageView(model: this.model)
        }
        Button("Image渲染测试").onClick({
             => this.model.setCSS("#path961 {stroke-width:"+"11.25"+";}", globalAbilityContext)
        }

        )
    }.width(50.percent).height(70.percent).backgroundColor(Color.WHITE)
}
}
