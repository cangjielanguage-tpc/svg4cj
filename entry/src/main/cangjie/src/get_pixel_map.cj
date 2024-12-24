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

    func getData(): PixelMap {
        let resourceManager = ResourceManager.getResourceManager(getStageContext(globalAbilityContext.getOrThrow()))
        let value: Array<UInt8> = resourceManager.getRawFileContent("circle.svg")
        let pixelmap = model.getSVGPixelMap(value, globalAbilityContext.getOrThrow())
        pixels = pixelmap
        return pixels.getOrThrow()
    }

    func build() {
        Column() {
            Image(getData())
            .width(400)
            .height(400)
            .border(width: 1.vp, color: Color(0x000000))
        }.height(100.percent)
    }
}
