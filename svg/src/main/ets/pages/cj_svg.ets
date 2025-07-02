import { NodeController, FrameNode } from '@kit.ArkUI';
import { requireCJLib } from 'libark_interop_loader.so'
import { CustomLib, CJSVGImageViewModel } from 'libsvg.so';
import { util } from '@kit.ArkTS';
import hilog from '@ohos.hilog';

export const global_customLib: CustomLib = requireCJLib("libsvg.so") as CustomLib

export const global_cjLib: CJLib = requireCJLib("libsvg.so") as CJLib

export interface CJLib {
  getCJResource(imageResource?: Resource): void
}

class CJNodeController extends NodeController {
  rootNode?: FrameNode = undefined
  model?: CJSVGImageViewModel
  cssValue: string = ''
  public freshCssValue: (value: string) => void = (value: string) => {
    this.cssValue = value
  }

  constructor(model?: CJSVGImageViewModel) {
    super()
    this.model = model
  }

  makeNode(ctx: UIContext): FrameNode | null {
    if (this.rootNode === undefined) {
      this.rootNode = new FrameNode(ctx)
      this.freshCssValue = global_customLib.getLoadCJPage(this.cssValue, this.model)
    }
    return this.rootNode
  }
}

@ComponentV2
export struct SVGImageView {
  private svgNode: CJNodeController | null = null
  @Param model?: SVGImageViewModel = undefined
  @Local cssValue: string = ''

  @Monitor('cssValue')
  onSvgChange(monitor: IMonitor) {
    this.svgNode?.freshCssValue(this.cssValue)
  }

  aboutToAppear(): void {
    if (this.model) {
      this.model.view = this
    }
    this.svgNode = new CJNodeController(this.getModel())
  }

  build() {
    NodeContainer(this.svgNode)
  }

  getModel(): CJSVGImageViewModel {
    let cjSVGImageViewModel: CJSVGImageViewModel = new global_customLib.CJSVGImageViewModel()
    if (this.model !== undefined) {
      if (this.model.filename != "") {
        cjSVGImageViewModel.setImageRawfile(this.model.filename)
      }
      if (this.model.svgFilename != "") {
        cjSVGImageViewModel.setImageRawfile(this.model.svgFilename)
      }
      if (this.model.data != "") {
        cjSVGImageViewModel.setFromString(this.model.data)
      }
      if (this.model.svgData != "") {
        cjSVGImageViewModel.setFromString(this.model.svgData)
      }
      if (this.model.resource !== undefined) {
        global_cjLib.getCJResource(this.model.resource)
      }
      if (this.model.svgResource !== undefined) {
        global_cjLib.getCJResource(this.model.svgResource)
      }
      if (this.cssValue != "") {
        cjSVGImageViewModel.setCSS(this.cssValue)
      }
    }
    return cjSVGImageViewModel
  }
}

export class SVGImageViewModel {
  filename: string = ''
  data: string = ''
  cssValue: string = ''
  resource?: Resource = undefined
  pixelMapWidth: number = 0
  pixelMapHeight: number = 0
  pixelMapValue?: ArrayBuffer = undefined
  view: SVGImageView | null = null
  svgData: string = ''
  svgResource?: Resource = undefined
  svgFilename: string = ''

  setSVGGetFromRawfile(svgFilename: string): void {
    this.svgFilename = svgFilename
  }

  setSVGGetFromString(svgData: string): void {
    this.svgData = svgData
  }

  setSVGGetFromResource(svgResource: Resource): void {
    this.svgResource = svgResource
  }

  setImageRawfile(filename: string): void {
    this.filename = filename
  }

  setImageResource(resource: Resource): void {
    this.resource = resource
  }

  setFromString(data: string): void {
    this.data = data
  }

  setCSS(cssValue: string): void {
    if (this.view) {
      this.view.cssValue = cssValue
    }
  }

  getSVGPixelMap(pixelmapValue?: Uint8Array): void {
    let cjSVGImageViewModel: CJSVGImageViewModel = new global_customLib.CJSVGImageViewModel()
    cjSVGImageViewModel.getSVGPixelMap(pixelmapValue)
    this.pixelMapWidth = cjSVGImageViewModel.getPixelMapWidth()
    this.pixelMapHeight = cjSVGImageViewModel.getPixelMapHeight()
    this.pixelMapValue = cjSVGImageViewModel.getPixelmapValue()
  }

  unit8ArrayToString(fileData: Uint8Array): string {
    let textDecoder = util.TextDecoder.create("utf-8", { ignoreBOM: true });
    return textDecoder.decodeWithStream(fileData, { stream: false })
  }
}

