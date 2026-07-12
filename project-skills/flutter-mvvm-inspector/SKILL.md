---
name: flutter-mvvm-inspector
description: >-
  在 Codex 内复用或后台启动由本 skill 管理的单个 Flutter debug app，通过已验证的 VM Service 调用 Flutter Inspector，开启 widget 选择、读取选中 widget 的 summary 信息并定位本地源码。用于已有 Flutter 项目的运行、日志、异常和 Inspector 定位；不用于接入外部 Flutter 进程、接受用户提供的 VM URI、创建项目或开发功能/API/mock。
---

# Flutter MVVM Inspector

始终从 Flutter app 根目录运行 bundled helper。把本 skill 目录记为 `SKILL_DIR`：

```bash
RUNTIME="$SKILL_DIR/scripts/flutter_runtime.py"
```

## 管理运行实例

需要启动、复用或排查运行实例时，先运行：

```bash
python3 "$RUNTIME" status
```

严格按状态处理：

- `running`：直接复用；禁止再次执行 `start`。
- `starting`：不要启动第二个进程；用 `logs` 查看进度并稍后重试 `status`。
- `unreachable`：VM endpoint 已生成，但当前沙箱无法访问；不要启动第二个进程。Inspector 操作按下文申请 localhost 网络权限。
- `not_started` 或 `stopped`：只有这两种状态才执行 `start`。

后台启动时只传递用户需要的 Flutter 参数；helper 会添加 `flutter run --debug --track-widget-creation`：

```bash
python3 "$RUNTIME" start -- -d macos --flavor dev --dart-define=KEY=value -t lib/main.dart
```

运行记录只存在 `.dart_tool/flutter-mvvm-inspector/`，一个项目只管理一个实例。不要扫描、接管或停止其他 Flutter 进程，不要接受用户提供的 VM Service URI。`flutter clean` 会清除运行记录。

只通过 helper 读取日志和异常；不要直接读取运行目录中的文件：

```bash
python3 "$RUNTIME" logs --lines 200
python3 "$RUNTIME" errors --lines 400
```

需要结束本 skill 保存的进程时运行 `python3 "$RUNTIME" stop`。停止后日志仍保留。

## 使用 Inspector

获取当前选中控件时只运行：

```bash
python3 "$RUNTIME" selected-summary
```

不要预先运行 `status` 或 `endpoint`。执行这条命令时直接申请 localhost 网络权限（在 Codex exec tool 中设置 `sandbox_permissions=require_escalated`，理由说明只读访问本项目受管 Flutter VM Service）；不要先在默认网络沙箱中试跑。它仍是唯一一条 shell 命令。

该命令会在内部重新验证受管 VM Service、查询全部非 system isolate、按 Inspector extension 能力选择唯一 Flutter isolate、开启 widget 选择，并以 `objectGroup=codex` 读取 summary selection。不要把流程拆成 `curl` 或 `jq` 命令，也不要缓存或显示 VM Service URI 和 isolate id。

成功时直接使用 stdout 的 JSON；它只包含 `description`、`creationLocation.file`、`line`、`column`、`name` 和 `createdByLocalProject`。如果命令提示尚未选择 widget，让用户在 app 中点选目标后再次运行同一命令。如果已在 localhost 权限下执行仍返回其他非零退出，再按“管理运行实例”处理。
