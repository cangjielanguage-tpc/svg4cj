import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';

@Entry
@ComponentV2
struct setCss {
  @Param cjSVGImageViewModel: SVGImageViewModel = new SVGImageViewModel()
  @Local flag: boolean = false

  aboutToAppear() {
    this.cjSVGImageViewModel.setImageRawfile("line.svg")
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Button('设置Css样式').fontSize(24).position({ x: 50, y: 50 })
        .onClick(() => {
          this.flag = !this.flag
          if (this.flag) {
            this.cjSVGImageViewModel.setCSS("#doodle { stroke: #00ff00; stroke-width: 2.0; }");
          } else {
            this.cjSVGImageViewModel.setCSS("#doodle { stroke: #ff0000; stroke-width: 2.0; }");
          }
        })
      Stack() {
        SVGImageView({ model: this.cjSVGImageViewModel })
      }
      .scale({ x: 0.7, y: 0.7 })
      .height("100%")
    }.height("100%").width('100%')
  }
}