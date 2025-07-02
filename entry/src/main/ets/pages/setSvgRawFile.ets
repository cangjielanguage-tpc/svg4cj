import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';

@Entry
@ComponentV2
struct setSvgRawFile {
  @Param cjSVGImageViewModel: SVGImageViewModel = new SVGImageViewModel()

  aboutToAppear(): void {
    this.cjSVGImageViewModel.setSVGGetFromRawfile("peach.svg")
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