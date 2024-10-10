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
            Flex(
                FlexParams(direction: FlexDirection.Column, alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceEvenly)) {
                Button("SetFromStringSample").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetFromStringSample")
                }
                Button("SetImageResourceSample").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetImageResourceSample")
                }
                Button("SetSvgSample").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetSvgSample")
                }
                Button("SetCssSample").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetCssSample")
                }
                Button("SetCssSample2").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetCssSample2")
                }
                Button("RenderDoodle7").fontSize(14).onClick {
                    => Router.push(url: "RenderDoodle7")
                }

                Button("testImage").fontSize(14).onClick {
                    => Router.push(url: "testImage")
                }

                Button("testImage2").fontSize(14).onClick {
                    => Router.push(url: "testImage2")
                }

                Button("RenderBox").fontSize(14).onClick {
                    => Router.push(url: "RenderBox")
                }

                Button("RenderCircle").fontSize(14).onClick {
                    => Router.push(url: "RenderCircle")
                }

                Button("RenderIcLauncherRound").fontSize(14).onClick {
                    => Router.push(url: "RenderIcLauncherRound")
                }

                Button("RenderLego").fontSize(14).onClick {
                    => Router.push(url: "RenderLego")
                }

                Button("RenderLine").fontSize(14).onClick {
                    => Router.push(url: "RenderLine")
                }

                Button("RenderPolygon").fontSize(14).onClick {
                    => Router.push(url: "RenderPolygon")
                }

                Button("RenderRubiksCube").fontSize(14).onClick {
                    => Router.push(url: "RenderRubiksCube")
                }

                Button("RenderThornRing").fontSize(14).onClick {
                    => Router.push(url: "RenderThornRing")
                }
                Button("RenderOldMan").fontSize(14).onClick {
                    => Router.push(url: "RenderOldMan")
                }
                Button("RenderEmptyHeart").fontSize(14).onClick {
                    => Router.push(url: "RenderEmptyHeart")
                }
                Button("RenderNotoEmojiU1f490").fontSize(14).onClick {
                    => Router.push(url: "RenderNotoEmojiU1f490")
                }
                Button("RenderOranges").fontSize(14).onClick {
                    => Router.push(url: "RenderOranges")
                }
                Button("RenderPeach").fontSize(14).onClick {
                    => Router.push(url: "RenderPeach")
                }
                Button("RenderTomato").fontSize(14).onClick {
                    => Router.push(url: "RenderTomato")
                }
                Button("RenderMerman").fontSize(14).onClick {
                    => Router.push(url: "RenderMerman")
                }
                Button("RenderDogCat").fontSize(14).onClick {
                    => Router.push(url: "RenderDogCat")
                }
                Button("RenderCock").fontSize(14).onClick {
                    => Router.push(url: "RenderCock")
                }
                Button("getSVGPixelMap").fontSize(14).onClick {
                    => Router.push(url: "getSVGPixelMap")
                }
            }.width(100.percent).height(100.percent).backgroundColor(Color(0xFFF1A493))
        }
    }

    private func initData(): Unit {
        this.menuWidth = 0.percent
    }
}
