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
                Button("Bugfix3D").fontSize(14).onClick {
                    => Router.push(url: "Bugfix3D")
                }
                Button("Bugfix58").fontSize(14).onClick {
                    => Router.push(url: "Bugfix58")
                }
                Button("BugfixAnimate").fontSize(14).onClick {
                    => Router.push(url: "BugfixAnimate")
                }
                Button("BugfixBasics5").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics5")
                }
                Button("BugfixBasics6").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics6")
                }
                Button("BugfixBasics7").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics7")
                }
                Button("BugfixBasics8").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics8")
                }
                Button("BugfixBasics9").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics9")
                }
                Button("BugfixBasics14").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics14")
                }
                Button("BugfixBasics16").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics16")
                }
                Button("BugfixBasics17").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics17")
                }
                Button("BugfixBasics18").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics18")
                }
                Button("BugfixBasics19").fontSize(14).onClick {
                    => Router.push(url: "BugfixBasics19")
                }
                Button("BugfixClipPath").fontSize(14).onClick {
                    => Router.push(url: "BugfixClipPath")
                }
                Button("BugfixDesc").fontSize(14).onClick {
                    => Router.push(url: "BugfixDesc")
                }
                Button("BugfixFeComponentTransfer").fontSize(14).onClick {
                    => Router.push(url: "BugfixFeComponentTransfer")
                }
                Button("BugfixFeMorphology").fontSize(14).onClick {
                    => Router.push(url: "BugfixFeMorphology")
                }
                Button("BugfixMaks").fontSize(14).onClick {
                    => Router.push(url: "BugfixMaks")
                }
                Button("BugfixMarker").fontSize(14).onClick {
                    => Router.push(url: "BugfixMarker")
                }
                Button("BugfixMarker1").fontSize(14).onClick {
                    => Router.push(url: "BugfixMarker1")
                }
                Button("BugfixMarker2").fontSize(14).onClick {
                    => Router.push(url: "BugfixMarker2")
                }
                Button("BugfixPattern").fontSize(14).onClick {
                    => Router.push(url: "BugfixPattern")
                }
                Button("BugfixPloygon").fontSize(14).onClick {
                    => Router.push(url: "BugfixPloygon")
                }
                Button("BugfixPloyLine").fontSize(14).onClick {
                    => Router.push(url: "BugfixPloyLine")
                }
                Button("BugfixRect").fontSize(14).onClick {
                    => Router.push(url: "BugfixRect")
                }
                Button("BugfixStop").fontSize(14).onClick {
                    => Router.push(url: "BugfixStop")
                }
                Button("BugfixUse").fontSize(14).onClick {
                    => Router.push(url: "BugfixUse")
                }
                Button("BugfixTspan").fontSize(14).onClick {
                    => Router.push(url: "BugfixTspan")
                }
                Button("BugfixText").fontSize(14).onClick {
                    => Router.push(url: "BugfixText")
                }
            }.width(100.percent).backgroundColor(Color(0xFFF1A493))
        }.scrollable(ScrollDirection.Vertical)
    }

    private func initData(): Unit {
        this.menuWidth = 0.percent
    }
}
