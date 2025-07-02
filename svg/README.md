<div align="center">
<h1>Svg4cj</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v1.0.2-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v1.1.3-brightgreen" style="display: inline-block;" />
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

主要类和函数接口说明详见 [API](https://gitcode.com/Cangjie-TPC/svg4cj/blob/develop/doc/feature_api.md)

## 使用说明

### 编译构建

1. 通过中心仓下载安装
      ```bash
      ohpm install @cangjie-tpc/svg
      ```

2. 在项目中使用 svg 项目

   ```arkts
   import { SVGImageView, SVGImageViewModel } from '@cangjie-tpc/svg';
   ```

### 功能示例

```ets
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
```

<p align="left">
<img src="https://raw.gitcode.com/Cangjie-TPC/svg4cj/raw/svg4cj_hybrid_cangjie-plugin-5.1.0.828/doc/assets/3D.png" width="30%" >
</p>

## 约束与限制

在下述版本验证通过：

| 编号 | 依赖构建工具                                       | 版本号       |
|----|----------------------------------------------|-----------|
| 1  | **DevEco Studio**                            | 6.1.1.280 |
| 2  | **cjc**                                      | v1.1.3    |
| 3  | **DevEco Studio-Cangjie Plugin 6.1.1 Beta1** | 6.1.1.280 |
| 4  | **compatibility-sdk-6.1.1.280**              | 6.1.1.280 |

svg4cj依赖三方库：

| 编号 | 依赖三方库         | 版本号      |
|----|---------------|----------|
| 1  | stdx          | v1.1.3.1 |

1、三方库静态链接和动态链接区别

- 静态链接：在编译期间，将所有依赖stdx的库函数和代码会被链接到最终的可执行文件中；生成的so中包含了所有需要的代码，不需要再依赖外部的stdx库。

  **缺点**： 由于静态链接将所有代码（包括库函数）都包含进最终的可执行文件，因此生成的可执行文件会比动态链接的文件要大。

- 动态链接：编译的har包中，会将所有使用到的stdx的二进制so添加到har的libs文件夹内；动态链接程序依赖于共享库（例如 .dll、.so），这些库在程序启动时或者运行时被加载到内存中。

  **缺点**：由于stdx版本之前存在不兼容，因此三方库和hap包依赖的stdx版本不一致情况下，存在运行crash情况。

当前三方库默认通过静态链接方式，如果有动态链接需求可以通过修改库代码中的cjpm.toml文件链接到stdx动态链接库目录，

```
[target]
  [target.aarch64-linux-ohos]
  	  ...
      path-option = [ "${AARCH64_LIBS}", "${AARCH64_MACRO_LIBS}", "${AARCH64_KIT_LIBS}", "../stdx_bin/linux_ohos_aarch64_llvm/static/stdx" ]
      [target.aarch64-linux-ohos.bin-dependencies.package-option]
  [target.x86_64-linux-ohos]
      ...
      path-option = [ "${X86_64_OHOS_LIBS}", "${X86_64_OHOS_MACRO_LIBS}", "${X86_64_OHOS_KIT_LIBS}", "../stdx_bin/linux_ohos_x86_64_llvm/static/stdx" ]
  [target.x86_64-unknown-windows-gnu]
    [target.x86_64-unknown-windows-gnu.bin-dependencies]
      path-option = [ "${X86_64_LIBS}", "${X86_64_MACRO_LIBS}", "../stdx_bin/windows_x86_64_llvm/static/stdx" ]
      [target.x86_64-unknown-windows-gnu.bin-dependencies.package-option]
```

修改如下：

```
[target]
  [target.aarch64-linux-ohos]
      ...
      path-option = [ "${AARCH64_LIBS}", "${AARCH64_MACRO_LIBS}", "${AARCH64_KIT_LIBS}", "../stdx_bin/linux_ohos_aarch64_llvm/dynamic/stdx" ]
      [target.aarch64-linux-ohos.bin-dependencies.package-option]
  [target.x86_64-linux-ohos]
      ...
      path-option = [ "${X86_64_OHOS_LIBS}", "${X86_64_OHOS_MACRO_LIBS}", "${X86_64_OHOS_KIT_LIBS}", "../stdx_bin/linux_ohos_x86_64_llvm/dynamic/stdx" ]
  [target.x86_64-unknown-windows-gnu]
    [target.x86_64-unknown-windows-gnu.bin-dependencies]
      path-option = [ "${X86_64_LIBS}", "${X86_64_MACRO_LIBS}", "../stdx_bin/windows_x86_64_llvm/dynamic/stdx" ]
      [target.x86_64-unknown-windows-gnu.bin-dependencies.package-option]
```

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

本项目基于 [Apache License 2.0](https://gitcode.com/Cangjie-TPC/svg4cj/blob/develop/LICENSE) ，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。