/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*

@Entry
@Component
class Index {
    private var menuWidth: String = "0%"

    func build() {
        Stack() {
            Flex(FlexParams(direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceEvenly)) {
                Button("SetFromStringSample").fontSize(14).onClick {
                    =>
                    Router.push(url: "SetFromStringSample")
                }

                Button("RenderSample").onClick {
                    => Router.push(url: "RenderSample")
                }
            }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(Color(0xFFF1A493))
        }
    }
}
