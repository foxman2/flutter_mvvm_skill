---
name: flutter-mvvm-inspector
description: >-
  用于在 Codex 内启动 Flutter debug app、获取 VM Service URI，并直接通过 Flutter Inspector VM Service extension 开启 widget 选择和定位源码位置。不依赖 Dart MCP active debug session。不用于创建新项目、开发正式功能、API/model 或 mock API；这些任务分别使用 flutter-mvvm-template、flutter-mvvm-feature-dev、flutter-mvvm-api-dev、flutter-mvvm-mock-api-dev。
---

# Flutter MVVM Inspector

使用这个 skill 在 Codex 内启动 Flutter app，并定位用户选择的 widget 源码位置。默认直走 VM Service 的 Flutter Inspector extension；不要为了 widget 选择调用 Dart MCP，也不要要求用户切到 IDE。

## 工作流程

1. 在 Flutter app 根目录启动 debug app：

```bash
flutter --print-dtd run --debug --track-widget-creation
```

`--print-dtd` 可保留，但此 skill 只需要 VM Service。保留用户给的 `-d`、`--flavor`、`--dart-define`、`-t` 等参数，并保持 `flutter run` 会话运行。
2. 从启动输出读取真实 VM Service URI，例如 `A Dart VM Service ... is available at: http://127.0.0.1:xxxxx/token=/`。不能编造 URI。
3. 从 VM Service 读取主 isolate：

```bash
curl -sS "$VM_SERVICE/getVM"
```

使用 `result.isolates` 中非 system isolate 的 `id` 作为 `ISOLATE_ID`。
4. 用 VM Service 开启 widget 选择模式：

```bash
curl -sS "$VM_SERVICE/ext.flutter.inspector.show?isolateId=$ISOLATE_ID&enabled=true"
```

确认返回里的 `enabled` 是 `true`。
5. 用户在 app 里点选目标 widget 后，直接读取 summary selection：

```bash
curl -sS "$VM_SERVICE/ext.flutter.inspector.getSelectedSummaryWidget?isolateId=$ISOLATE_ID&objectGroup=codex"
```

`objectGroup` 是必需参数；不要写成 `groupName`，否则 Flutter 会抛 `parameters.containsKey('objectGroup')` assertion。
6. 只提取并报告最小字段：`description`、`creationLocation.file`、`creationLocation.line`、`creationLocation.column`、`creationLocation.name`、`createdByLocalProject`。不要输出整棵 JSON 树。
7. 如果用户想知道“原始命中节点”，再调用：

```bash
curl -sS "$VM_SERVICE/ext.flutter.inspector.getSelectedWidget?isolateId=$ISOLATE_ID&objectGroup=codex"
```

仍只摘取最小字段。一般回答“我的代码是哪一段”时优先用 summary selection，因为它会把 Flutter framework 内部命中映射回本地项目创建的 widget。

如果 app 已经由 IDE、DevTools 或 Flutter 工具启动，直接使用它提供的真实 VM Service URI。目标是全程在 Codex 内完成；不要把 VS Code active debug session 或 Dart MCP 当成必需前置条件。
