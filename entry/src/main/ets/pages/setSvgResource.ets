import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';

@Entry
@ComponentV2
struct setSvgResource {
  @Param cjSVGImageViewModel: SVGImageViewModel = new SVGImageViewModel()

  aboutToAppear() {
    const res = $r('app.media.old_man');
    res.bundleName = 'com.cangjie.svg4cj';
    res.moduleName = 'entry';
    this.cjSVGImageViewModel.setSVGGetFromResource(res)
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