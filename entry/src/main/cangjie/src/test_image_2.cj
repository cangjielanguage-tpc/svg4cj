/**
 * Created on 2024/8/26
 */
package ohos_app_cangjie_entry

import ohos.base.*
import ohos.component.*
import ohos.state_manage.*
import ohos.state_macro_manage.*
import ohos.image.Image as MultiImage
import ohos.image.Component as ImageComponent
import ohos.image.InitializationOptions
import ohos.image.PixelMapFormat
import ohos.image.PixelMap
import ohos.image.ImageSource
import ohos.image.createImageSource
import ohos.image.createPixelMap
import ohos.image.Size as UniqueImageSize
import ohos.hilog.*
import ohos.image.createPixelMap

@Entry
@Component
class testImage2 {
    var pixelMap: ?PixelMap = None

    protected func aboutToAppear() {
        let resourceManager = ResourceManager.getResourceManager(getStageContext(globalAbilityContext.getOrThrow()))
        let value: Array<UInt8> = resourceManager.getRawFileContent("cock.svg")
        let imageSource: ImageSource = createImageSource(value)
        this.pixelMap = imageSource.createPixelMap()
    }

    func build() {
        Stack() {
            Column {
                Image(this.pixelMap.getOrThrow()).width(400).height(400)
            }
            .scale(x: 0.7, y: 0.7)
            .height(100.percent)
        }
        .width(100.percent)
        .height(100.percent)
    }
}
