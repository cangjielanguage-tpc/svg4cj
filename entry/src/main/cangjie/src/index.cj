/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*

@Entry
@Component
class Index {
    private var menuWidth: Length = 0.percent

    func build() {
        Stack() {
            Flex(FlexParams(direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceEvenly)) {
                Button("SetFromStringSample").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetFromStringSample")
                }

                Button("RenderSample").fontSize(14).onClick {
                    => Router.push(url: "RenderSample")
                }

                Button("testImage").fontSize(14).onClick {
                    => Router.push(url: "testImage")
                }
            }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(Color(0xFFF1A493))
        }
    }

    private func initData(): Unit {
        this.menuWidth = 0.percent
    }
}
