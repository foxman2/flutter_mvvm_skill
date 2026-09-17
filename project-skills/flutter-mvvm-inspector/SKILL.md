---
name: flutter-mvvm-inspector
description: >-
  启动和管理当前 Flutter MVVM 项目的调试实例，执行热重载、热重启、日志和网络检查，定位选中 Widget。不接管外部进程，不接受 VM Service URI。
---

# Flutter 调试与 Inspector

只操作 helper 管理的当前项目实例。在 Flutter 项目根目录运行：

```bash
RUNTIME=".codex/skills/flutter-mvvm-inspector/scripts/flutter_runtime.py"
```

## 常用命令

| 目标 | 命令 |
|---|---|
| 启动或复用 | `python3 "$RUNTIME" start -- -d <device-id> -t lib/main.dart` |
| 热重载，保留页面状态 | `python3 "$RUNTIME" reload` |
| 热重启，重置应用状态 | `python3 "$RUNTIME" restart` |
| 查看状态 | `python3 "$RUNTIME" status` |
| 查看日志 | `python3 "$RUNTIME" logs --lines 200` |
| 查看异常 | `python3 "$RUNTIME" errors --lines 400` |
| 清空并开启网络记录 | `python3 "$RUNTIME" network-start` |
| 读取网络记录 | `python3 "$RUNTIME" network-logs --limit 100` |
| 定位选中 Widget | `python3 "$RUNTIME" selected-summary` |
| 打开已连接的 DevTools | `python3 "$RUNTIME" devtools` |
| 停止实例 | `python3 "$RUNTIME" stop` |

不知道设备 ID 时，先运行 `flutter devices`。用户要求模拟器时，选明确标记为 `simulator` 的设备，不用 `ios` 这样的泛化名称。

## 判断是否启动成功

- `start` 有现成受管进程就复用，没有才执行 `flutter run`。它会等待 VM Service，iOS 冷构建可能很久没有输出。
- 只有 `start` 退出码为 0 且输出 `running`，才算调试连接就绪。
- 命令失败、输出 `starting`、旧日志写过启动成功，或进程还活着，都不能证明连接就绪。

| status | 含义 |
|---|---|
| `not_started` / `stopped` | 没有受管实例 |
| `starting` | 还在等待 VM Service |
| `unreachable` | 已取得连接地址，但当前无法访问 |
| `running` | 当前 VM Service 可访问 |

`running` 不代表模拟器窗口已在桌面前台。

## 操作规则

- 直接执行需要的命令。不预先扫描进程、端口或连接地址，不读取 helper 原始状态文件。
- 不接管其他 Flutter 进程，不接受用户提供的 VM Service URI。
- localhost 不可达时，取得所需权限后重试同一命令。不要把失败的 `reload` 或 `restart` 换成 `start`。
- 只有状态明确为 `not_started` 或 `stopped` 时才新建实例。
- `start` 和 `restart` 会尝试开启 DevTools Network。网络记录失败会输出 warning，但启动或重启仍可能成功；需要网络检查时，等应用就绪后再运行 `network-start`。
- `restart` 清空并重开网络记录，`reload` 保留记录。只有需要丢弃旧请求时才运行 `network-start`。
- 网络日志含完整 URI、headers、cookies 和 body。除非用户明确要求，不保存到文件或发送到外部。

## 定位和修改 Widget

- 每次都重新运行 `selected-summary`，只用本次返回的 `creationLocation`。没有选中项时，请用户重新选择。
- 此 skill 只修改选中 Widget 的纯展示代码，不新增或修改测试。
- 如果涉及状态、callback、校验、交互、数据、API、导航、弹层结果或异步行为，停止此工作流并说明超出范围。
