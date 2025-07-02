import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';

@Entry
@ComponentV2
struct setImageRawFile {
  @Param cjSVGImageViewModel: SVGImageViewModel = new SVGImageViewModel()

  aboutToAppear(): void {
    this.cjSVGImageViewModel.setImageRawfile("3D.svg")
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