---
name: flutter-mvvm-inspector
description: >-
  通过 bundled helper 管理已有 Flutter 项目的单个受管 debug 实例，读取应用、异常与 HTTP 网络请求日志，并使用 Flutter Inspector 定位当前选中 Widget 的本地源码。用于运行诊断、排查网络请求，或定位、修改“当前选中” Widget；不用于接管外部进程、接受用户提供的 VM Service URI、创建项目或独立开发功能。
---

# Flutter MVVM Inspector

从 Flutter 应用根目录执行命令，并把当前 skill 目录记为 `SKILL_DIR`：

```bash
RUNTIME="$SKILL_DIR/scripts/flutter_runtime.py"
```

## 按目标执行

```bash
# 启动或复用应用
# 先把 FLUTTER_TARGET_DEVICE 替换为项目支持且当前可用的设备 ID
FLUTTER_TARGET_DEVICE="<device-id>"
python3 "$RUNTIME" start -- -d "$FLUTTER_TARGET_DEVICE" -t lib/main.dart

# 热重启当前受管实例
python3 "$RUNTIME" restart

# 开启 Widget 选择并读取选中结果
python3 "$RUNTIME" selected-summary

# 失败后诊断，或按用户要求执行
python3 "$RUNTIME" status
python3 "$RUNTIME" errors --lines 400
python3 "$RUNTIME" network-start
# 在应用中复现请求后读取最近记录
python3 "$RUNTIME" network-logs --limit 100
python3 "$RUNTIME" logs --lines 200
python3 "$RUNTIME" stop
```

- 直接执行目标命令，不先搜索进程、解析 endpoint 或运行 `status`。
- `start` 自动复用受管实例；只在 `--` 后传项目实际需要的 device、flavor、target 或 dart-define，helper 会固定添加 debug、Widget tracking 和受管参数。
- `restart` 只向验证过的当前项目受管进程发送 Flutter 热重启信号，并等待日志确认完成；不要在调用前搜索进程、读取 PID 或解析 endpoint。
- 排查 API 调用时，先执行 `network-start` 清空旧记录并开启 DevTools Network，再让用户复现操作，最后执行 `network-logs`。不要在开启记录前让用户复现。
- `network-logs` 通过受管 VM Service 聚合所有应用 isolate 的 `dart:io` HTTP Profile，适用于 iOS、Android 和其他原生 Dart 目标，包括 Dio 请求；输出方法、脱敏查询参数后的 URI、状态、耗时与错误，不输出 isolate id、headers、cookies 或 body。
- `network-start` 或 `network-logs` 遇到 localhost 限制时，申请只读访问当前项目受管 VM Service 后重试；保持命令完整，不打印或传递 URI、token 与 isolate id。
- 每次 `restart` 或应用重新启动后都重新执行 `network-start`；HTTP Profile 只包含开启记录后发出的请求。
- 选择项目已包含平台目录且当前可用的设备；优先使用能提供原生 Dart VM Service 的 iOS、Android 或 macOS 目标，不假设项目支持某个固定平台。
- 若环境限制 localhost，在执行 `selected-summary` 前申请只读访问当前项目受管 VM Service；保持命令完整，不打印或传递 URI、token 与 isolate id。
- 只通过 helper 查看日志和异常，不直接读取 `.dart_tool/flutter-mvvm-inspector/`。

## 定位或修改当前选中 Widget

1. 每次新的“当前选中”请求都重新执行 `selected-summary`，只使用本次返回的 `creationLocation` 定位源码。
2. 没有选中 Widget 时请用户重新选择；新结果成功前不复用上一次目标。
3. 用户只要求定位时，读取并报告本次 `creationLocation` 对应的源码，不修改文件。
4. 用户明确要求修改时，只调整本次选中 Widget 及直接相关的纯展示代码，遵循相邻实现、l10n、主题和现有状态绑定；若需求涉及状态、callback、校验、交互、数据、API、导航、弹层结果或异步行为，停止本工作流并报告超出当前范围。
5. 纯展示修改不新增或修改测试；修改后格式化受影响文件，运行 `flutter analyze` 和受影响的已有测试，并通过实际界面验收。

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
