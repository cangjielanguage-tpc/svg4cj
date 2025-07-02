# Svg4cj 特性文档

## 介绍

Svg4cj是一个SVG图片的解析器和渲染器，解析SVG图片并渲染到页面上。它是一个用仓颉语言编写的适用于鸿蒙系统的三方库。

## 1 Svg4cj

### 1.1 Svg4cj

#### 1.1.1 API Description

```ets
export class SVGImageViewModel {

    /*
     * 读取 resources/rawfile 文件，构造 SVG 对象，展示 SVG 图像
     * 
     * 参数 svgFilename - 读取 resources/rawfile 文件
     */
    setSVGGetFromRawfile(svgFilename: string): void

    /*
     * 读取 SVG 源文件内容，构造 SVG 对象，展示 SVG 图像
     * 
     * 参数 svgData - 读取 SVG 源文件内容
     */
    setSVGGetFromString(svgData: string): void
    
    /*
     * 读取 Resource 资源，构造 SVG 对象，展示 SVG 图像
     * 
     * 参数 svgResource - 读取 Resource 资源
     */
    setSVGGetFromResource(svgResource: Resource): void
    
    /*
     * 读取 resources/rawfile 文件，展示 SVG 图像
     * 
     * 参数 filename - 读取 resources/rawfile 文件
     */
    setImageRawfile(filename: string): void
    
    /*
     * 读取 Resource 资源，展示 SVG 图像
     * 
     * 参数 resource - 读取 Resource 资源
     */
    setImageResource(resource: Resource): void
    
    /*
     * 读取 SVG 源文件内容，展示 SVG 图像
     * 
     * 参数 data - 读取 SVG 源文件内容
     */
    setFromString(data: string): void
    
    /*
     * 设置自定义 css 样式，无法通过此接口修改 svg 原有形状
     * 
     * 参数 css - 设置自定义 css 样式
     */
    setCSS(cssValue: string): void
    
    /*
     * 获取 SVG 格式 PixelMap 对象，展示内容
     * 
     * 参数 pixelmapValue - SVG 源数据
     */
    getSVGPixelMap(pixelmapValue?: Uint8Array): void

    /*
     * 工具类，将 Uint8Array 转为 string 字符串
     * 
     * 返回值 string - 返回转换后的 string 字符串
     */
    unit8ArrayToString(fileData: Uint8Array): string
}
```