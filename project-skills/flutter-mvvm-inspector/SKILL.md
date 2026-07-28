---
name: flutter-mvvm-inspector
description: >-
  通过 bundled helper 管理已有 Flutter 项目的单个受管 debug 实例，查看日志与异常，并使用 Flutter Inspector 定位当前选中 Widget 的本地源码。用于运行诊断或定位、修改“当前选中” Widget；不用于接管外部进程、接受用户提供的 VM Service URI、创建项目或独立开发功能。
---

# Flutter MVVM Inspector

从 Flutter 应用根目录执行命令，并把当前 skill 目录记为 `SKILL_DIR`：

```bash
RUNTIME="$SKILL_DIR/scripts/flutter_runtime.py"
```

## 按目标执行

```bash
# 启动或复用应用
python3 "$RUNTIME" start -- -d macos -t lib/main.dart

# 开启 Widget 选择并读取选中结果
python3 "$RUNTIME" selected-summary

# 失败后诊断，或按用户要求执行
python3 "$RUNTIME" status
python3 "$RUNTIME" errors --lines 400
python3 "$RUNTIME" logs --lines 200
python3 "$RUNTIME" stop
```

- 直接执行目标命令，不先搜索进程、解析 endpoint 或运行 `status`。
- `start` 自动复用受管实例；只在 `--` 后传项目实际需要的 device、flavor、target 或 dart-define，helper 会固定添加 debug、Widget tracking 和受管参数。
- 若环境限制 localhost，在执行 `selected-summary` 前申请只读访问当前项目受管 VM Service；保持命令完整，不打印或传递 URI、token 与 isolate id。
- 只通过 helper 查看日志和异常，不直接读取 `.dart_tool/flutter-mvvm-inspector/`。

## 定位或修改当前选中 Widget

1. 每次新的“当前选中”请求都重新执行 `selected-summary`，只使用本次返回的 `creationLocation` 定位源码。
2. 没有选中 Widget 时请用户重新选择；新结果成功前不复用上一次目标。
3. 定位后读取源码；实际修改按对应开发 skill 的规则执行。

## 失败恢复

- `no widget is selected`：请用户点击目标 Widget 后重试，不重启。
- localhost 被限制或状态为 `unreachable`：取得本地网络权限后重试，不重启。
- VM Service、Inspector isolate 或 extension 未就绪：执行 `start`；持续失败再查看 `status`、`logs` 和 `errors`。
- 状态为 `not_started` 或 `stopped`：执行 `start`。
- 仅在实例已退出、启动失败或持续无响应时，使用本次启动的相同 Flutter 参数执行 `stop` 后 `start`。不要从其他进程或原始状态文件提取参数，也不要用重启掩盖业务异常。

## 安全边界

- 只操作 helper 创建并验证的当前项目实例；一个项目只管理一个实例。
- 不接管、停止或复用其他 Flutter 进程，不扫描端口或搜索系统进程。
- 不输出 VM Service URI、认证 token、isolate id 或原始状态文件。
- 不接受用户提供的 endpoint，也不使用 `endpoint` 子命令驱动 Inspector。
- 扩大网络或进程访问范围前遵循宿主 Agent 的授权规则。
