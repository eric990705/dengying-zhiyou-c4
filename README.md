# 灯影智游

面向 C4 移动应用创新赛启迪赛道的 SwiftUI 原生应用原型。

当前仓库包含两套交付：

- `app/iOS`：正式参赛用 SwiftUI iOS App 入口。
- `app/macOS`：本机可直接打开的 SwiftUI 演示 App，便于没有完整 Xcode 时立即验收。

## 立即运行

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
- 拍照识别演示流程
- 灯组知识卡片
- 主题路线导览
- 识别反馈表单
- 本地灯组知识库 JSON

## GitHub MCP

本机 Codex 已配置 GitHub MCP，通过 `gh` 的 macOS keyring 登录态获取 token，不在仓库或配置中明文保存令牌。

