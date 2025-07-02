import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';

@Entry
@ComponentV2
struct setImageResource {
  @Param cjSVGImageViewModel: SVGImageViewModel = new SVGImageViewModel()

  aboutToAppear(): void {
    const res = $r('app.media.dog_cat');
    res.bundleName = 'com.cangjie.svg4cj';
    res.moduleName = 'entry';
    this.cjSVGImageViewModel.setImageResource(res)
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

