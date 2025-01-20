<div align="center">
<h1>Svg4cj</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.0.1-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.58.3-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-NA-red" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/project-open-brightgreen" style="display: inline-block;" />
</p>

## 介绍

Svg4cj是一个SVG图片的解析器和渲染器，解析SVG图片并渲染到页面上。它是一个用仓颉语言编写的适用于鸿蒙系统的三方库。

## 优势

- 能够渲染大多数标准的 SVG 图像
- 性能好、内存占用低

### 特性

1. 支持渲染大多数 SVG 1.1 规范的图像，详见约束与限制

### 源码目录

```shell
├─AppScope
├─doc        # API文档和使用手册存放目录                   
├─entry      # 示例代码文件夹    
├─hvigor  # 构建工具目录              
├─svg    # svg 库文件夹                   
│  └─src
│      └─main
│          ├─cangjie
│          │  └─src           # 库源代码目录
│          └─resources
├─README.md  # svg4cj 介绍及使用说明
```

- `AppScope` 全局资源存放目录和应用全局信息配置目录
- `doc` API文档和使用手册存放目录
- `entry` 工程模块 - 编译生成一个HAP
- `entry src` APP代码目录
- `entry src main` APP项目目录
- `entry src main cangjie` 仓颉代码目录
- `entry src main resources` 资源文件目录
- `svg` 工程模块 - 编译生成一个har包
- `svg src` 模块代码目录
- `svg src main` 模块项目目录
- `svg src main cangjie` 仓颉代码目录
- `svg src main resources` 资源文件目录
- `svg src main cangjie src` 仓颉源码文件目录
- `hvigor` 构建工具目录

### 接口说明

主要类和函数接口说明详见 [API](doc/feature_api.md)

## 使用说明

### 编译构建

1. 通过module引入
   1. 克隆下载项目
   2. 将svg模块拷贝到应用项目下
   3. 修改自身应用 entry 下的 oh-package.json5 文件，在 dependencies 字段添加 "svg": "file:../svg"
      ```json
      {
         "name": "entry",
         "version": "1.0.0",
         "description": "Please describe the basic information.",
         "main": "",
         "author": "",
         "license": "",
        "dependencies": {
            "svg": "file:../svg"
        }
      }
      ```
   4. 修改自身应用 entry/src/main/cangjie 下的 cjpm.toml 文件，在 [dependencies] 字段下添加 svg = {path = "../../../../svg/src/main/cangjie", version = "1.0.0"}
      ```toml
      [dependencies]
          svg = {path = "../../../../svg/src/main/cangjie", version = "1.0.0"}
      ```
   5. 在项目中使用 import svg.* 引用svg项目
      ```cangjie
      import svg.*
      ```
   6. 在测试项目时，若使用的是模拟器环境，请在 entry/build-profile.json5 文件的 "cangjieOptions": {} 添加 "abiFilters": ["x86_64"]，如果是真机环境，请将 ["x86_64"] 修改为 ["arm64-v8a"]

2. 把 svg4cj 作为三方库依赖引入
    1. 目标工程把 svg4cj 依赖库作为 git submodule 引入

    ```
    > cd $工程根目录
    > mkdir third-party
    > cd third-party
    > git submodule add "https://gitcode.com/Cangjie-TPC/svg4cj.git"
    ```
    2. 修改自身应用 entry/src/main/cangjie 下的 cjpm.toml 文件，添加依赖
    ```toml
    [dependencies]
        svg = {path = "../../../../third-party/svg4cj/svg/src/main/cangjie", version = "1.0.0"}
     ```
    3. 在项目中使用 svg 组件
       ```cangjie
       import svg.*
       ```

### 功能示例

```cangjie
@Entry
@Component
class RenderMerman {
    @State var model: SVGImageViewModel = SVGImageViewModel()
    var flag: Bool = false

    protected override func aboutToAppear() {

        // merman.svg 文件存放于 entry/src/main/resources/rawfile 文件夹下
        this.model.setImageRawfile("merman.svg", globalAbilityContext)
    }

    func build() {
        Column {
            SVGImageView(model: this.model)
        }.width(50.percent).height(70.percent).backgroundColor(Color.WHITE)
    }
}
```

<p align="left">
<img src="./doc/assets/merman.png" width="30%" >
</p>

## 约束与限制

在下述版本验证通过：

    DevEco Studio 5.0.1 Release
    Cangjie Support Plugin 5.0.5.306

1只支持 SVG 1.1 规范格式图像中的以下元素：
```text
   <svg>
   <g>
   <defs>
   <a>
   <use>
   <path>
   <rect>
   <circle>
   <ellipse>
   <line>
   <polyline>
   <polygon>
   <text>
   <tspan>
   <tref>
   <zwitch> 也是 <switch>
   <symbol>
   <marker>
   <linearGradient>
   <radialGradient>
   <stop>
   <clipPath>
   <textPath>
   <pattern>
   <image>
   <view>
   <mask>
   <style>
```
2. 本库默认支持的 Text 标签内容字体大小约为 17.px，若需要动态调整字体大小，请自行设定。
3. .svg 源文件开头第一行若以回车开头，会导致渲染不生效。请不要以回车开头。
4. .svg 源文件中若颜色值为 #fff，CangjieUI 默认补全为 #000fff，而非 #fff000，建议颜色值手动补全。
5. 暂未支持图片渐变效果。

## 开源协议

本项目基于 [Apache License 2.0](./LICENSE) ，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。