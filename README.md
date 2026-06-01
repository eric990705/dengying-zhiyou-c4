# 灯影智游

面向 C4 移动应用创新赛启迪赛道的 SwiftUI 原生应用。

当前仓库包含两套交付：

- `app/iOS`：正式参赛用 SwiftUI iOS App 入口。
- `app/macOS`：本机可直接打开的 SwiftUI 演示 App，便于没有完整 Xcode 时立即验收。

## 立即运行

双击项目目录里的 `打开灯影智游.command`，脚本会自动构建并打开本机演示 App。

也可以在终端运行：

```bash
./tools/build_macos_demo.sh
open build/灯影智游.app
```

## 生成 Xcode 工程

```bash
xcodegen generate
```

生成后使用完整 Xcode 打开 `DengyingZhiyou.xcodeproj`，选择 `DengyingZhiyouiOS` 运行到 iPhone 模拟器或真机。

## 当前范围

- 首页运营概览
- iOS 相机/相册图片输入
- Vision/Core ML 目标检测管线
- 灯组目标框、置信度和多候选结果
- 灯组知识卡片
- 主题路线导览
- 识别反馈表单
- 本地灯组知识库 JSON

## 目标检测模块

检测入口在 `app/shared/LanternDetector.swift`：

- 优先加载 App Bundle 中的 `LanternDetector.mlmodelc`，通过 `VNCoreMLRequest` 执行目标检测。
- 当前仓库未放训练权重时，会自动回退到 `VNGenerateObjectnessBasedSaliencyImageRequest`，仍然能对真实图片输出候选目标框。
- 检测结果统一映射为 `LanternDetection`，包含灯组、标签、置信度、检测框和检测引擎。
- iOS 页面支持“拍照检测”“相册检测”“样张检测”；macOS 演示支持“导入图片”“样张检测”。

后续训练好自贡彩灯检测模型后，把 `LanternDetector.mlmodel` 放进 `app/resources`，重新运行：

```bash
xcodegen generate
```

Xcode 会在构建时编译成 `LanternDetector.mlmodelc`，App 会自动走 Core ML 模型分支。

## GitHub MCP

本机 Codex 已配置 GitHub MCP，通过 `gh` 的 macOS keyring 登录态获取 token，不在仓库或配置中明文保存令牌。
