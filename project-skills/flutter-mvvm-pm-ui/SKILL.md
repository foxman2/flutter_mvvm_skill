---
name: flutter-mvvm-pm-ui
description: >-
  在已有 Flutter MVVM 项目中完成用户明确要求的 PM 评审、UI 原型、隔离预览或非发布展示调整，包括展示型 UI、文案、样式、lib/product_preview/ 页面、对应 AppPage 和预览局部样例数据。用于不改变正式业务行为的产品展示；不用于正式业务逻辑、domain API contract、依赖装配、正式 model、真实 Dio 请求或正式页面迁移。
---

# Flutter MVVM PM UI

## 允许范围

- 调整正式页面、共用 Widget 或 theme 的纯展示层，不改变已有 ViewModel 行为。
- 在 `lib/product_preview/pages/<feature>/` 新增按正式 MVVM 命名和结构实现的隔离页面，为其创建 AppPage 并注册到 Product Preview。
- 需要列表、详情或状态等业务形态数据时，在对应 `lib/product_preview/` 目录内使用局部 fixture 或预览 ViewModel，不创建 domain contract、全局 wiring、mock service 或正式 model。

## 工作流程

1. 读取相关 `_page.dart`、现有组件、`lib/product_preview/` 示例与 registry；需要数据时优先复用预览目录内已有样例。
2. 现有 UI 微调只改展示层；新页面或流程原型只放入 `lib/product_preview/`，并使用同目录 ViewModel 管理展示状态和临时交互。
3. 业务形态数据和纯布局占位、tab、选中态或筛选项等临时状态都保持在预览局部，不进入正式数据层。
4. 复用项目已有组件、theme、间距、按钮和弹层风格。
5. 格式化、运行 `flutter analyze` 并通过实际 Product Preview 验收；纯展示、静态 fixture 和静态文案改动不新增或修改测试；预览 ViewModel 状态、callback 或临时交互改动先检查已有测试是否直接断言受影响的输入、动作、状态、输出或 contract，仅执行到相关代码不算直接覆盖；覆盖充分时复跑并记录依据，覆盖不足时才新增或更新最小测试；混合改动只覆盖行为部分。
6. 交付时列出 PM 改动、预览局部样例数据和不得直接发布的预览页面。

## 关键边界

- 不修改正式 ViewModel 的状态、异步、业务动作、导航决策或数据持久化，也不修改与预览无关的 AppPage、route parser 和正式依赖。
- 不新增或修改 domain API contract、ApiService wiring、mock service、正式 model、真实 Dio 请求、认证、埋点、推送或持久化逻辑。
- 不得新增或修改任何 Dart define、环境解析、默认环境、启动配置、构建脚本或 CI 参数。
- 仅在项目已有开关时原样使用 `--dart-define=server=mock`；缺少开关或需要新环境参数时停止 PM 修改并报告缺失配置。

## 读取参考

- 修改现有 UI 或判断权限边界：读 `references/ui-scope.md`。
- 新增或注册隔离预览页面：读 `references/product-preview-pattern.md`。
