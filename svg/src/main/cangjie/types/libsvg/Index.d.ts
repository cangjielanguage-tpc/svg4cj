import { Context } from "@kit.AbilityKit"

export declare class CJSVGImageViewModel {
    setImageRawfile(filename: string): void
    setFromString(data: string): void
    setCSS(cssValue: string): void
    getSVGPixelMap(pixelmapValue: ArrayBuffer): void
    getPixelmapValue(): ArrayBuffer
    getPixelMapWidth(): number
    getPixelMapHeight(): number
    constructor ()
}

export declare interface CustomLib {
    CJSVGImageViewModel: {new (): CJSVGImageViewModel}
    setGlobalContext(context: Context): void
    getLoadCJPage(cssValue: string, model: CJSVGImageViewModel): (cssValue: string) => void
}
