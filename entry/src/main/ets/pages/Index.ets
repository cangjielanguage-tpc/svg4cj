import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  build() {
    Scroll() {
      Column() {
        Row() {
          Text("")// 宽度
            .width(10)
          Button("1. 读取RawFile文件，展示SVG图像")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/setImageRawFile' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')

        Row() {
          Text("")// 宽度
            .width(10)
          Button("2. 读取Resource资源，展示SVG图像")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/setImageResource' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')

        Row() {
          Text("")// 宽度
            .width(10)
          Button("3. 读取SVG源文件内容，展示SVG图像")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/setFromStringSample' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')

        Row() {
          Text("")// 宽度
            .width(10)
          Button("4. 设置SVG图像某部分CSS样式")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/setCss' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')

        Row() {
          Text("")// 宽度
            .width(10)
          Button("5. 读取RawFile文件，构造SVG对象，展示SVG图像")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/setSvgRawFile' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')

        Row() {
          Text("")// 宽度
            .width(10)
          Button("6. 读取Resource资源，构造SVG对象，展示SVG图像")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/setSvgResource' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')

        Row() {
          Text("")// 宽度
            .width(10)
          Button("7. 读取SVG源文件内容，构造SVG对象，展示SVG图像")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/setSvgStr' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')

        Row() {
          Text("")// 宽度
            .width(10)
          Button("8. 获取SVG格式PixelMap对象，展示内容")
            .height(50)// 高度
            .layoutWeight(1)// 容器尺寸确定时，元素与兄弟节点主轴布局尺寸按照权重进行分配，忽略本身尺寸设置仅在Row/Column/Flex布局中生效
            .fontColor(0xFFFFFFFF)// 文本颜色
            .backgroundColor(0xFFFF0000)// 背景颜色
            .margin({ top: 5, bottom: 5 })// 外边距
            .align(Alignment.Center)// 内容对齐方式
            .fontSize(12)// 字体大小
            .onClick(e => {
              // 点击动作触发该方法调用
              router.pushUrl({ url: 'pages/getSVGPixelMap' })
            })
          Text("")// 宽度
            .width(10)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
  }
}