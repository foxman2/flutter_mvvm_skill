---
name: flutter-mvvm-inspector
description: >-
  管理已有 Flutter 项目的单个 debug 运行实例，并通过已验证的本地 VM Service 使用 Flutter Inspector：查看运行状态、日志与异常，开启 Widget 选择，读取选中 Widget 的摘要并定位本地源码。适用于任何能够运行 bundled Python helper 并按需访问 localhost 的 AI Agent；不用于接管外部 Flutter 进程、使用用户提供的 VM Service URI、创建项目，或开发功能、API 与 mock。
---

# Flutter MVVM Inspector

从 Flutter 应用根目录执行所有命令。把当前 skill 目录记为 `SKILL_DIR`，并使用 bundled helper：

```bash
RUNTIME="$SKILL_DIR/scripts/flutter_runtime.py"
```

不要自行发现 Flutter 进程、解析 VM Service 地址或用 `curl` 重组 Inspector 流程。helper 负责限定进程范围、验证本地 endpoint、隐藏服务凭据并输出安全结果。

## 管理应用实例

需要启动、复用或排查应用时，先检查状态：

```bash
python3 "$RUNTIME" status
```

根据 stdout 的单个状态值执行：

- `running`：复用现有实例，不要再次执行 `start`。
- `starting`：不要启动第二个实例；用 `logs` 查看进度，稍后再运行 `status`。
- `unreachable`：endpoint 已生成但当前执行环境不能访问 localhost；不要启动第二个实例。按“检查选中 Widget”处理本地网络权限。
- `not_started` 或 `stopped`：允许执行 `start`。

只把项目实际需要的 Flutter 参数放在 `--` 后。helper 会固定添加 `flutter run --debug --track-widget-creation`：

```bash
python3 "$RUNTIME" start -- -d macos --flavor dev --dart-define=KEY=value -t lib/main.dart
```

一个项目只管理一个实例，运行记录保存在 `.dart_tool/flutter-mvvm-inspector/`。不要接管、停止或复用其他 Flutter 进程，也不要接受或传入用户提供的 VM Service URI。`flutter clean` 会删除这些运行记录。

只通过 helper 查看日志和异常，不要直接读取运行目录：

```bash
python3 "$RUNTIME" logs --lines 200
python3 "$RUNTIME" errors --lines 400
```

需要结束本 skill 管理的实例时运行：

```bash
python3 "$RUNTIME" stop
```

停止后日志仍会保留。

## 检查选中 Widget

直接执行以下命令，不要预先执行 `status` 或 `endpoint`：

```bash
python3 "$RUNTIME" selected-summary
```

这条命令需要访问受管 Flutter VM Service 的 localhost endpoint。若宿主 Agent 或执行环境默认限制本地网络，应在执行前使用该环境提供的授权、提权或网络放行机制，并向用户说明用途是只读访问当前项目受管的 Flutter VM Service。不要通过反复试跑、打印 endpoint 或拆分成其他网络命令来绕过限制。

helper 会重新验证受管 VM Service，检查全部非 system isolate，按 Inspector extension 能力选择唯一 Flutter isolate，开启 Widget 选择，并读取 summary selection。保持它为一条完整命令；不要缓存、展示或向其他工具传递 VM Service URI 与 isolate id。

成功时使用 stdout 的 JSON。结果只包含：

- `description`
- `creationLocation.file`
- `creationLocation.line`
- `creationLocation.column`
- `creationLocation.name`
- `createdByLocalProject`

用 `creationLocation` 定位并检查本地源码。若提示尚未选择 Widget，让用户在正在运行的应用中点选目标，再执行同一命令。若已具备 localhost 访问权限但命令仍以非零状态退出，再回到“管理应用实例”检查状态、日志和异常。

## 安全边界

- 只操作 helper 创建并验证的当前项目实例。
- 不输出 VM Service URI、认证 token、isolate id 或运行目录中的原始状态文件。
- 不执行用户提供的 endpoint，不扫描端口，不搜索系统中的其他 Flutter 进程。
- 不用 `endpoint` 子命令驱动 Inspector；该子命令仅供 helper 的兼容性与诊断测试使用。
- 任何需要扩大网络或进程访问范围的操作，都先遵循宿主 Agent 的授权规则。
