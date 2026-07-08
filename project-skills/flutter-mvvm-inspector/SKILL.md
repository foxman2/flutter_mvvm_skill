---
name: flutter-mvvm-inspector
description: >-
  用于在 Codex 内启动或接入 Flutter debug app、获取真实 VM Service URI，并通过 Flutter Inspector VM Service extension 开启 widget 选择、读取选中 widget 的 summary 信息和定位本地源码位置。不用于创建新项目、开发正式功能、API/model 或 mock API；这些任务分别使用 flutter-mvvm-template、flutter-mvvm-feature-dev、flutter-mvvm-api-dev、flutter-mvvm-mock-api-dev。
---

# Flutter MVVM Inspector

使用这个 skill 在 Codex 内启动或接入 Flutter debug app，并直接通过 VM Service 调用 Flutter Inspector extension，定位用户点选的 widget 源码位置。

## 核心流程

1. 在 Flutter app 根目录启动 debug app，并保持 `flutter run` 会话运行：

```bash
flutter run --debug --track-widget-creation
```

保留用户给的 `-d`、`--flavor`、`--dart-define`、`-t` 等参数。如果用户已经提供运行中 app 的真实 VM Service URI，直接使用该 URI。
2. 从启动输出或用户提供的信息读取真实 VM Service URI，格式通常是 `http://127.0.0.1:xxxxx/token=/`。不能编造 URI。
3. 从 VM Service 读取 isolate 列表：

```bash
curl -sS "$VM_SERVICE/getVM"
```

使用 `result.isolates` 中非 system isolate 的 `id` 作为 `ISOLATE_ID`。
4. 开启 widget 选择模式：

```bash
curl -sS "$VM_SERVICE/ext.flutter.inspector.show?isolateId=$ISOLATE_ID&enabled=true"
```

确认返回里的 `enabled` 是 `true`。
5. 用户在 app 里点选目标 widget 后，读取 summary selection：

```bash
curl -sS "$VM_SERVICE/ext.flutter.inspector.getSelectedSummaryWidget?isolateId=$ISOLATE_ID&objectGroup=codex"
```

`objectGroup` 是必需参数；不要写成 `groupName`，否则 Flutter 会抛 `parameters.containsKey('objectGroup')` assertion。
6. 只提取并报告最小字段：`description`、`creationLocation.file`、`creationLocation.line`、`creationLocation.column`、`creationLocation.name`、`createdByLocalProject`。不要输出整棵 JSON 树。

## 原始命中节点

一般回答“我的代码是哪一段”时，优先使用 summary selection，因为它会把 Flutter framework 内部命中映射回本地项目创建的 widget。只有当用户明确想知道原始命中节点时，才调用：

```bash
curl -sS "$VM_SERVICE/ext.flutter.inspector.getSelectedWidget?isolateId=$ISOLATE_ID&objectGroup=codex"
```

仍只摘取最小字段，并说明它可能比 summary selection 更接近用户实际点中的底层 widget。
