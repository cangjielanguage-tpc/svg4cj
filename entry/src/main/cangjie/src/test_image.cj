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
import ohos.image.createPixelMap
import ohos.image.Size as UniqueImageSize

@Entry
@Component
class testImage {
    var pixelMap: ?PixelMap = None
    @State var loaded: Bool = false
    @State var flag: Bool = false

    func build() {
        Column {
            Button("Image渲染测试").onClick({ => flag = true})
            if (flag) {
                Image(@r(app.media.circle))
                .width(300)
                .height(200)
            }
        }
        .width(100.percent)
        .height(100.percent)
    }
}