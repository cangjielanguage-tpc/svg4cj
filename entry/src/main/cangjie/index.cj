/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*

@Entry
@Component
class Index {
    private var menuWidth: Length = 0.percent

    func build() {
        Scroll() {
            Column {
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
                Button("SetSvgSample2").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetSvgSample2")
                }
                Button("SetSvgSample3").fontSize(14).onClick {
                    =>
                    this.initData()
                    Router.push(url: "SetSvgSample3")
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
                Button("Render3D").fontSize(14).onClick {
                    => Router.push(url: "Render3D")
                }
                Button("Render58").fontSize(14).onClick {
                    => Router.push(url: "Render58")
                }
                Button("RenderAnimate").fontSize(14).onClick {
                    => Router.push(url: "RenderAnimate")
                }
                Button("RenderBasics5").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics5")
                }
                Button("RenderBasics6").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics6")
                }
                Button("RenderBasics7").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics7")
                }
                Button("RenderBasics8").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics8")
                }
                Button("RenderBasics9").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics9")
                }
                Button("RenderBasics14").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics14")
                }
                Button("RenderBasics16").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics16")
                }
                Button("RenderBasics17").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics17")
                }
                Button("RenderBasics18").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics18")
                }
                Button("RenderBasics19").fontSize(14).onClick {
                    => Router.push(url: "RenderBasics19")
                }
                Button("RenderDesc").fontSize(14).onClick {
                    => Router.push(url: "RenderDesc")
                }
                Button("RenderFeComponentTransfer").fontSize(14).onClick {
                    => Router.push(url: "RenderFeComponentTransfer")
                }
                Button("RenderFeMorphology").fontSize(14).onClick {
                    => Router.push(url: "RenderFeMorphology")
                }
                Button("RenderMaks").fontSize(14).onClick {
                    => Router.push(url: "RenderMaks")
                }
                Button("RenderMarker").fontSize(14).onClick {
                    => Router.push(url: "RenderMarker")
                }
                Button("RenderMarker1").fontSize(14).onClick {
                    => Router.push(url: "RenderMarker1")
                }
                Button("RenderMarker2").fontSize(14).onClick {
                    => Router.push(url: "RenderMarker2")
                }
                Button("RenderPattern").fontSize(14).onClick {
                    => Router.push(url: "RenderPattern")
                }
                Button("RenderPloygon").fontSize(14).onClick {
                    => Router.push(url: "RenderPloygon")
                }
                Button("RenderPloyLine").fontSize(14).onClick {
                    => Router.push(url: "RenderPloyLine")
                }
                Button("RenderRect").fontSize(14).onClick {
                    => Router.push(url: "RenderRect")
                }
                Button("RenderStop").fontSize(14).onClick {
                    => Router.push(url: "RenderStop")
                }
                Button("Render404").fontSize(14).onClick {
                    => Router.push(url: "Render404")
                }
                Button("RenderIconsvg").fontSize(14).onClick {
                    => Router.push(url: "RenderIconsvg")
                }
                Button("RenderTspan").fontSize(14).onClick {
                    => Router.push(url: "RenderTspan")
                }
                Button("RenderText").fontSize(14).onClick {
                    => Router.push(url: "RenderText")
                }
                Button("RenderFunDraw").fontSize(14).onClick {
                    => Router.push(url: "RenderFunDraw")
                }
                Button("RenderAbstract").fontSize(14).onClick {
                    => Router.push(url: "RenderAbstract")
                }
                Button("RenderA").fontSize(14).onClick {
                    => Router.push(url: "RenderA")
                }
                Button("RenderFeColorMatrix").fontSize(14).onClick {
                    => Router.push(url: "RenderFeColorMatrix")
                }
                Button("RenderFeDiffuseLighting").fontSize(14).onClick {
                    => Router.push(url: "RenderFeDiffuseLighting")
                }
            }.width(100.percent).backgroundColor(Color(0xFFF1A493))
        }.scrollable(ScrollDirection.Vertical)
    }

    private func initData(): Unit {
        this.menuWidth = 0.percent
    }
}
