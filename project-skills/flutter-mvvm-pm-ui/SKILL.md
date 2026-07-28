---
name: flutter-mvvm-pm-ui
description: >-
  在已有 Flutter MVVM 项目中完成用户明确要求的 PM 评审、UI 原型、隔离预览或非发布展示调整，包括展示型 UI、文案、样式、lib/product_preview/ 页面和对应 AppPage。需要临时业务数据时同时使用 flutter-mvvm-mock-api-dev；不用于正式业务逻辑、已确认 API/model、真实 Dio 请求或正式页面迁移。
---

# Flutter MVVM PM UI

## 允许范围

- 调整正式页面、共用 Widget 或 theme 的纯展示层，不改变已有 ViewModel 行为。
- 在 `lib/product_preview/pages/<feature>/` 新增按正式 MVVM 命名和结构实现的隔离页面，为其创建 AppPage 并注册到 Product Preview。
- 需要列表、详情或状态等业务形态数据时，同时使用 `$flutter-mvvm-mock-api-dev`；相关 contract、wiring、mock service 和 mock-only model 必须标记待开发审核。

## 工作流程

1. 读取相关 `_page.dart`、现有组件、`lib/product_preview/` 示例与 registry；需要数据时同时读取现有 mock API。
2. 现有 UI 微调只改展示层；新页面或流程原型只放入 `lib/product_preview/`，并使用同目录 ViewModel 管理展示状态和临时交互。
3. 业务形态数据走 mock service；只有纯布局占位、tab、选中态或筛选项等小型 UI 状态保留在预览 ViewModel。
4. 复用项目已有组件、theme、间距、按钮和弹层风格。
5. 格式化、运行 `flutter analyze` 并通过实际 Product Preview 验收；仅在修复正式页面回归时新增针对性测试。
6. 交付时列出 PM 改动、待开发审核的 mock/API 文件和不得直接发布的预览页面。

## 关键边界

- 不修改正式 ViewModel 的状态、异步、业务动作、导航决策或数据持久化，也不修改与预览无关的 AppPage、route parser 和正式依赖。
- 不实现已确认的正式 API/model、真实 Dio 请求、认证、埋点、推送或持久化逻辑。
- 不得新增或修改任何 Dart define、环境解析、默认环境、启动配置、构建脚本或 CI 参数；同时使用 mock skill 不扩大这项权限。
- 仅在项目已有开关时原样使用 `--dart-define=server=mock`；缺少开关或需要新环境参数时停止 PM 修改并交由开发处理。

## 读取参考

- 修改现有 UI 或判断权限边界：读 `references/ui-scope.md`。
- 新增或注册隔离预览页面：读 `references/product-preview-pattern.md`。
- 使用业务形态数据时直接同时使用 `$flutter-mvvm-mock-api-dev`，不再加载重复的 PM mock 规则。
