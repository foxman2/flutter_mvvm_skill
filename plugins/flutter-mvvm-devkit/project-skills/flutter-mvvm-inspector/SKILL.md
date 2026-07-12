---
name: flutter-mvvm-inspector
description: >-
  管理已有 Flutter 项目的单个受管 debug 运行实例，并通过已验证的本地 VM Service 使用 Flutter Inspector：启动或复用应用、查看日志与异常、开启 Widget 选择、读取选中 Widget 的摘要并定位本地源码。用于诊断已有 Flutter 应用的运行状态和界面；不用于接管外部 Flutter 进程、使用用户提供的 VM Service URI、创建项目，或开发功能、API 与 mock。
---

# Flutter MVVM Inspector

## 提供的功能

- 启动、复用或停止当前项目的单个受管 Flutter debug 实例。
- 查看该实例的日志和 Flutter/Dart 异常。
- 开启 Widget 选择，读取选中 Widget 的摘要并定位本地源码。

从 Flutter 应用根目录执行命令，把当前 skill 目录记为 `SKILL_DIR`：

```bash
RUNTIME="$SKILL_DIR/scripts/flutter_runtime.py"
```

## 按目标直接执行

```bash
# 启动或复用应用
python3 "$RUNTIME" start -- -d macos --flavor dev --dart-define=KEY=value -t lib/main.dart

# 开启 Widget 选择并读取选中结果
python3 "$RUNTIME" selected-summary

# 只在失败后诊断，或按用户要求执行
python3 "$RUNTIME" status
python3 "$RUNTIME" errors --lines 400
python3 "$RUNTIME" logs --lines 200
python3 "$RUNTIME" stop
```

- 优先执行目标命令，不要先搜索进程、解析 endpoint 或运行 `status`。
- `start` 会自动复用已有受管实例。只在 `--` 后传入项目需要的 Flutter 参数；helper 会固定添加 `flutter run --debug --track-widget-creation` 及其受管参数。
- 执行 `selected-summary` 前，若环境限制 localhost，先申请只读访问当前项目受管 Flutter VM Service 的权限。保持它为一条完整命令，不要打印、缓存或传递 VM Service URI 与 isolate id。
- `selected-summary` 成功后，使用 stdout JSON 的 `description`、`creationLocation` 和 `createdByLocalProject`；按 `creationLocation` 定位并检查源码。
- 只通过 helper 查看日志和异常，不要直接读取 `.dart_tool/flutter-mvvm-inspector/` 中的文件。

## 失败恢复

- 提示 `no widget is selected`：让用户在运行中的应用里点击目标 Widget，再执行 `selected-summary`；不要重启。
- 提示需要 localhost network access 或状态为 `unreachable`：取得本地网络权限后重试；不要重启。
- 提示 VM Service、Inspector isolate 或 extension 尚未 ready：执行 `start`，稍后重试；持续失败时查看 `status`、`logs` 和 `errors`。
- 状态为 `not_started` 或 `stopped`：执行 `start`。
- 确认受管实例已经退出、启动失败或持续无响应：使用本次启动的相同 Flutter 参数重启：

```bash
python3 "$RUNTIME" stop
python3 "$RUNTIME" start -- <原 Flutter 参数>
```

不要从其他进程或原始运行文件提取启动参数。Flutter/Dart 业务异常应先通过 `errors` 定位，不要把重启当作异常修复。

## 安全边界

- 只操作 helper 创建并验证的当前项目实例；一个项目只管理一个实例。
- 不接管、停止或复用其他 Flutter 进程，不扫描端口，不搜索系统进程。
- 不输出 VM Service URI、认证 token、isolate id 或原始状态文件。
- 不接受用户提供的 endpoint，也不使用 `endpoint` 子命令驱动 Inspector。
- 任何扩大网络或进程访问范围的操作都先遵循宿主 Agent 的授权规则。
