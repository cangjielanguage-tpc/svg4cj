/**
 * Created on 2024/10/12
 */
package ohos_app_cangjie_entry

import ohos.state_macro_manage.*
import ohos.image.PixelMap

@Entry
@Component
class getSVGPixelMap {
    @State
    var pixels: ?PixelMap = Option<PixelMap>.None

    @State
    var model: SVGImageViewModel = SVGImageViewModel()

    @State
    var model2: SVGImageViewModel = SVGImageViewModel()

    func build() {
        Column() {
            Button("点击").onClick(
                {
                    =>
                    let resourceManager = ResourceManager.getResourceManager(getStageContext(globalAbilityContext.getOrThrow()))
                    let value: Array<UInt8> = resourceManager.getRawFileContent("cock.svg")
                    let pixelmap = model.getSVGPixelMap(value, globalAbilityContext.getOrThrow())
                    this.pixels = pixelmap
                }
            )
            if (let Some(v) <- pixels) {
                Image(v)
                .width(400)
                .height(400)
                .border(width: 1.vp, color: Color(0x000000))
            }
        }.height(100.percent)
    }
}
