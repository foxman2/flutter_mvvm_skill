---
name: flutter-mvvm-code-map
description: >-
  扫描已有 Flutter 项目并创建、更新或校验 docs/FEATURE_CODE_MAP.md，把用户理解的功能与别名映射到稳定的代码入口和检索锚点。用于用户要求生成、补全或刷新功能代码地图，或希望 AI 更快定位功能对应的页面、ViewModel、Repository、API 和测试时；不用于开发业务功能、重构目录或编写详细架构文档。
---

# Flutter MVVM Code Map

为已有 Flutter 项目维护一份简洁的功能代码索引。地图只负责帮助人和 AI 找到可靠入口，具体实现继续从源码追踪。

## 输出约束

- 默认只创建或更新 `docs/FEATURE_CODE_MAP.md`；除非用户明确要求，不修改 `AGENTS.md` 或业务代码。
- 使用项目相对路径和精确类名，不使用绝对路径、Markdown 文件链接或行号。
- 保持三列表格：`功能/别名`、`代码入口`、`检索锚点`。
- 每个功能只保留 1～3 个稳定入口和 2～5 个可直接通过 `rg` 搜索的锚点。
- 不增加详细调用链、实现说明、参数、状态流转或完整文件清单。
- 代码与地图冲突时以代码为准；无法从源码确认的信息不要猜测。

使用以下结构，只保留项目中实际存在的全局入口：

```md
# 功能代码地图

## 全局入口

- 页面路由：`lib/navigation/app_page.dart`
- 依赖装配：`lib/app_container.dart`
- API 聚合：`lib/services/api/api_service.dart`
- 产品预览：`lib/product_preview/product_preview_registry.dart`

## 功能索引

| 功能/别名 | 代码入口 | 检索锚点 |
|---|---|---|
| 登录、验证码登录、login | `lib/pages/login/` | `LoginAppPage`、`LoginViewModel`、`AuthRepository` |
```

## 工作流程

1. 确认当前目录是目标 Flutter 项目，至少存在 `pubspec.yaml` 和 `lib/`；否则停止并说明缺少的项目入口。
2. 如果 `docs/FEATURE_CODE_MAP.md` 已存在，先读取并保留仍然准确的人工分组和用语，只做必要更新。
3. 使用 `rg --files` 找到路由、页面目录、ViewModel、依赖装配、Repository、API service、model、测试和产品预览入口。不要假定示例路径一定存在。
4. 优先从路由定义、页面目录和产品预览注册表识别功能，再通过 import、构造器和依赖装配追踪少量稳定锚点。
5. 从 l10n 文案、页面名称和已有产品术语提取用户用语；同时保留常用英文代码名。没有证据时只使用代码中的名称。
6. 按用户理解的功能合并条目，不按 `pages`、`services`、`models` 等技术分层拆分。通用弹窗、基础组件和框架设施默认不作为独立功能。
7. 创建 `docs/`（如有需要）并通过最小补丁写入地图。已有文件中与目标格式无关的人工说明不得擅自删除。
8. 校验每个路径实际存在，并用 `rg` 确认每个检索锚点拼写准确；删除或修正已确认失效的条目。

## 更新取舍

- 功能数量较少时使用单个表格；功能较多时可在同一文件内按业务域增加二级标题，但每个分组仍使用相同三列。
- 页面目录能稳定代表整个功能时优先记录目录；职责分散时记录最明确的页面或路由文件。
- ViewModel、AppPage case、Repository 和 API service 适合作为检索锚点；只在它们能显著缩短追踪路径时记录。
- 测试通常不单独占列；只有测试是该功能最可靠入口时才放入“代码入口”。

完成后报告地图路径、覆盖的功能数量，以及因无法从源码确认而省略的内容。
