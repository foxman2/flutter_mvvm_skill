---
name: flutter-mvvm-inspector
description: >-
  用于启动 Flutter debug app、从启动输出获取 Dart Tooling Daemon URI、用 Dart MCP 连接该 app，并开启 widget 选择和获取选中 widget 源码位置。不用于创建新项目、开发正式功能、API/model 或 mock API；这些任务分别使用 flutter-mvvm-template、flutter-mvvm-feature-dev、flutter-mvvm-api-dev、flutter-mvvm-mock-api-dev。
---

# Flutter MVVM Inspector

使用这个 skill 启动 Flutter app，并把 Dart MCP 连接到这个运行中的 app，然后再做 widget 选择和源码定位。

## 工作流程

1. 在 Flutter app 根目录启动 debug app：

```bash
flutter --print-dtd run --debug --track-widget-creation
```

保留用户给的 `-d`、`--flavor`、`--dart-define`、`-t` 等参数，并保持 `flutter run` 会话运行。
2. 从启动输出读取真实 DTD URI，例如 `The Dart Tooling Daemon is available at: ws://...`。不能编造 URI。
3. 用 Dart MCP `connect_dart_tooling_daemon(uri)` 连接这个 app。连接失败或重连时，重新获取新的 DTD URI。
4. 连接成功后，用 Dart MCP `set_widget_selection_mode(true)` 开启选择，再用 `get_selected_widget` 获取用户选中的 widget；需要父子上下文时调用 `get_widget_tree`。

如果 app 已经由 IDE 或 Flutter 工具启动，直接使用它提供的真实 DTD URI 连接。
