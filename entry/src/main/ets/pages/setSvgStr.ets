import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';
import { baseManager } from '../entryability/EntryAbility';

@Entry
@ComponentV2
struct setSvgStr {
  @Param cjSVGImageViewModel: SVGImageViewModel = new SVGImageViewModel()

  aboutToAppear() {
    let value = baseManager?.getRawFileContentSync('oranges.svg')
    if (value) {
      let data = this.cjSVGImageViewModel.unit8ArrayToString(value)
      this.cjSVGImageViewModel.setSVGGetFromString(data)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Stack() {
        SVGImageView({ model: this.cjSVGImageViewModel })
      }
    }
    .height("100%")
    .padding({ top: 40 })
    .margin({ bottom: 20 })
  }
}