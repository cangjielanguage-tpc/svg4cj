import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';
import { baseManager } from '../entryability/EntryAbility';

@Entry
@ComponentV2
struct setFromStringSample {
  @Param cjSVGImageViewModel: SVGImageViewModel = new SVGImageViewModel()

  aboutToAppear(): void {
    let value = baseManager?.getRawFileContentSync("old_man.svg")
    if (value) {
        let data: string = this.cjSVGImageViewModel.unit8ArrayToString(value)
        this.cjSVGImageViewModel.setFromString(data)
    }
  }

  build() {
    Row() {
      Column() {
        SVGImageView({ model: this.cjSVGImageViewModel })
      }
      .width('100%')
    }
    .height('100%')
  }
}

