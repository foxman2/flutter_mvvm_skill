---
name: flutter-mvvm-inspector
description: >-
  管理已有 Flutter MVVM 项目的单个受管 debug 实例，并按需检查网络请求或当前选中 Widget。用于启动、热重载、热重启、日志诊断和 Inspector 源码定位；不用于接管外部进程或接受 VM Service URI。
---

# Flutter MVVM Inspector

从 Flutter 项目根目录运行 bundled helper：

```bash
RUNTIME=".codex/skills/flutter-mvvm-inspector/scripts/flutter_runtime.py"
```

| 目标 | 命令 |
|---|---|
| 启动或复用 | `python3 "$RUNTIME" start -- -d <device-id> -t lib/main.dart` |
| 热重载，保留页面状态 | `python3 "$RUNTIME" reload` |
| 热重启，重置应用状态 | `python3 "$RUNTIME" restart` |
| 状态 / 日志 / 异常 | `python3 "$RUNTIME" status`、`logs --lines 200`、`errors --lines 400` |
| 清空 / 读取网络记录 | `python3 "$RUNTIME" network-start`、`network-logs --limit 100` |
| 当前选中 Widget | `python3 "$RUNTIME" selected-summary` |
| 打开已连接 DevTools | `python3 "$RUNTIME" devtools` |
| 停止受管实例 | `python3 "$RUNTIME" stop` |

## 规则

- 直接执行目标命令，不预先扫描进程、端口或 endpoint，也不读取 helper 原始状态文件。
- 只操作 helper 验证的当前项目实例；不接管外部 Flutter 进程，不接受用户提供的 VM Service URI。
- localhost 不可达时，取得权限后重试同一命令；不要把 `reload` 或 `restart` 改成 `start`。只有明确返回 `not_started` 或 `stopped` 时才启动实例。
- `start` 自动开启网络记录，`restart` 清空后重新记录，`reload` 保留记录；只在需要丢弃旧请求时执行 `network-start`。
- 网络日志包含完整 URI、headers、cookies 和 body，视为敏感数据；除非用户明确要求，不持久化或外发。
- 每次定位当前 Widget 都重新执行 `selected-summary`，只使用本次 `creationLocation`；没有选中项时请用户重新选择。
- Inspector 修改仅限选中 Widget 的纯展示代码；涉及状态、交互、数据、API 或导航时，改用对应功能开发流程。
