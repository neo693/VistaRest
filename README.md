# 远眺 · VistaRest

面向长期使用电脑人群的本地 macOS 护眼工作节奏工具。

当前首版包含：

- 菜单栏倒计时
- 护眼模式、经典番茄、深度工作
- 可调整的工作、微休息和长休息时长
- 系统通知和提示音
- 标准/严格多显示器休息遮罩
- 暂停、继续、提前休息、跳过和重置
- 今日专注时长、完成休息次数、最长连续专注和跳过次数
- UserDefaults 本地保存，不需要账号或网络

## 运行

需要 macOS 13 或更新版本，以及 Swift 5.9+。

直接以 Swift 可执行程序运行：

```bash
swift run VistaRest
```

构建并打开本地菜单栏 `.app`：

```bash
./run-local.sh
```

生成本机安装包（Release `.dmg` 和 `.zip`）：

```bash
./package-local.sh
```

产物会放在 `dist/` 目录。安装包使用本地 ad-hoc 签名，仅用于本机运行测试。

运行不启动 UI 的基础自检：

```bash
swift run VistaRest --self-check
```

首次点击“开始专注”时，系统会询问通知权限。菜单栏里点击“设置”可以调整模式、时长和提醒强度。

## 当前不包含

暂不包含 iPhone/Apple Watch、iCloud、快捷指令、专注模式联动、智能离开检测和视频/会议识别。这些功能留到后续版本。
