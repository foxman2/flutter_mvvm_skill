---
name: flutter-mvvm-inspector
description: >-
  管理已有 Flutter MVVM 项目的单个受管 debug 实例，并按需检查网络请求或当前选中 Widget。用于启动、热重载、热重启、日志诊断和 Inspector 源码定位；不用于接管外部进程或接受 VM Service URI。
---

# Flutter MVVM Inspector

从 Flutter 项目根目录运行受管 helper：

```bash
RUNTIME=".codex/skills/flutter-mvvm-inspector/scripts/flutter_runtime.py"
```

## 操作

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

设备 ID 未知时先运行 `flutter devices`；用户要求模拟器时选择明确标记为
`simulator` 的设备，不使用 `ios` 等泛化名称。

## 启动与状态

- `start` 会复用当前项目的受管进程；没有进程时才执行新的 `flutter run`。它会等待
  VM Service 就绪，iOS 冷构建期间可能长时间没有输出。
- 只有 `start` 退出码为 0 且输出 `running`，才能确认受管调试连接已经就绪。命令失败、
  `starting`、旧日志中的启动记录或仅有存活进程都不能作为启动成功依据。
- `status` 的含义：`not_started` / `stopped` 表示没有受管实例，`starting` 表示进程仍在
  等待 VM Service，`unreachable` 表示 endpoint 已生成但当前无法访问，`running` 表示
  当前受管 VM Service 可访问。`running` 不证明 Simulator 窗口位于桌面前台。
- `start` 和 `restart` 会尽力开启 DevTools Network。网络记录不可用时命令仍可启动或
  重启成功，并在 stderr 给出 warning；需要网络诊断时，待应用就绪后再执行
  `network-start`。

## 操作边界

- 直接执行目标命令，不预先扫描进程、端口或 endpoint，也不读取 helper 原始状态文件。
- 只操作 helper 验证的当前项目实例；不接管外部 Flutter 进程，不接受用户提供的 VM Service URI。
- localhost 不可达时，取得权限后重试同一命令；不要把失败的 `reload` 或 `restart`
  改成 `start`。只有状态明确为 `not_started` 或 `stopped` 时才新建实例。
- `restart` 清空并重新开启网络记录，`reload` 保留已有记录；只在需要丢弃旧请求时执行
  `network-start`。
- 网络日志包含完整 URI、headers、cookies 和 body，视为敏感数据；除非用户明确要求，不持久化或外发。
- 每次定位当前 Widget 都重新执行 `selected-summary`，只使用本次 `creationLocation`；没有选中项时请用户重新选择。
- Inspector 修改仅限选中 Widget 的纯展示代码，纯展示修改不新增或修改测试。涉及状态、callback、校验、交互、数据、API、导航、弹层结果或异步行为，停止本工作流并报告超出当前范围。
