import { SVGImageViewModel } from '@cangjie-tpc/svg';
import { baseManager } from '../entryability/EntryAbility';
import image from '@ohos.multimedia.image';

@Entry
@ComponentV2
struct getSVGPixelMap {
  @Local pixels?: PixelMap = undefined

  aboutToAppear(): void {
    let model: SVGImageViewModel = new SVGImageViewModel()
    let arr = baseManager?.getMediaContentSync($r('app.media.old_man').id)
    model.getSVGPixelMap(arr)
    let opts: image.InitializationOptions = {
      size: {width: model.pixelMapWidth, height: model.pixelMapHeight}
    }
    this.pixels = image.createPixelMapSync(model.pixelMapValue, opts)
  }

  build() {
    Row() {
      Column() {
        Image(this.pixels).width(400).height(400)
      }
      .width('100%')
    }
    .height('100%')
  }
}

