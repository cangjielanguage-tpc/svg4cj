# Svg4cj 特性文档

## 介绍

Svg4cj是一个SVG图片的解析器和渲染器，解析SVG图片并渲染到页面上。它是一个用仓颉语言编写的适用于鸿蒙系统的三方库。

## 1 Svg4cj

### 1.1 Svg4cj

#### 1.1.1 API Description

```cangjie
public class SVGImageViewModel {
    
    /*
     * 构造
     */
    public init(): Unit
    
    /*
     * 设置图表绘制的上下文
     * 
     * 参数 context2D - 图表绘制的上下文，参考 ohos 画布组件中的 class CanvasRenderingContext2D 绘制对象类
     */
    public func setContext2D(context2D: CanvasRenderingContext2D): Unit

    /*
     * 设置 SVG 对象
     * 
     * 参数 svg - 要传入的自定义 svg 类对象
     * 参数 context - Ability状态上下文
     * 参数 css - String 类型的缺省参数，表示传入的渲染可选项内容，只能修改 css 样式，无法通过接口修改 svg 原有形状
     */
    public func setSVG(svg: SVG, context: ?AbilityContext, css!: String = this.renderOptions.css): Unit

    /*
     * 设置自定义 css 样式，无法通过此接口修改 svg 原有形状
     * 
     * 参数 css - 设置自定义 css 样式
     * 参数 context - Ability状态上下文
     */
    public func setCSS(css: String, context: ?AbilityContext): Unit
    
    /*
     * 根据资源对象设置svg 并渲染
     * 
     * 参数 resource - Resource对象，参考 ohos 资源管理下的 class Resource 资源类
     * 参数 context - Ability状态上下文
     */
    public func setImageResource(resource: OhosResource, context: ?AbilityContext): Unit
    
    /*
     * 根据文件对象设置svg 并渲染
     * 
     * 参数 filename - 文件地址
     * 参数 context - Ability状态上下文
     */
    public func setImageRawfile(filename: String, context: ?AbilityContext): Unit

    /*
     * 根据 svg 源文件中的内容设置svg 并渲染
     * 
     * 参数 data - svg 源文件的内容
     * 参数 context - Ability状态上下文
     */
    public func setFromString(data: String, context: ?AbilityContext): Unit
    
    /*
     * 生成svg类型的PixelMap对象，目前缺少离屏绘制对象(OffscreenCanvasRenderingContext2D)，导致 pixelMap 无法生成，此接口暂无法使用
     * 
     * 参数 data - 待生成的数组
     * 参数 context - Ability状态上下文
     * 参数 screen - 缺省参数 screen 表示当前屏幕密度比例
     * 返回值 PixelMap - PixelMap对象
     */
    public func getSVGPixelMap(data: Array<UInt8>, context: ?AbilityContext, screen!: Float64 = pxTovp): PixelMap

}
```