---
name: flutter-mvvm-pm-ui
description: >-
  用于已有 Flutter MVVM 项目中的产品经理 UI 预览和受限展示层改动：调整展示型 UI、文案或样式，在 lib/product_preview/ 新增遵循正式页面组织规则的隔离预览页，优先用 mock API 数据辅助界面评审，并产出待开发审核说明。不用于正式业务逻辑、正式 ViewModel 行为、正式 AppPage 导航、正式功能集成、已确认后端 API/model 或正式页面迁移；按任务使用 flutter-mvvm-feature-dev、flutter-mvvm-api-dev 或 flutter-mvvm-mock-api-dev。
---

# Flutter MVVM PM UI

使用这个 skill 帮产品经理在 Flutter MVVM 项目里做 UI 预览、文案和展示层调整。核心原则是：PM 可以动 UI，不能把原型直接变成正式业务逻辑。

## 职责边界

- 可以修改展示层：`lib/pages/**/<feature>_page.dart`、`lib/widgets/`、`lib/theme/` 或项目已有纯 UI 目录。
- 可以修改产品预览入口按钮：`lib/product_preview/product_preview_entry_button.dart`。
- 可以新增预览页面：只放在 `lib/product_preview/pages/<feature>/`，按正式页面的 page/ViewModel 职责拆分组织，并通过 `product_preview_registry.dart` 注册。
- 可以为预览页面新增同目录 preview-only ViewModel，用于展示状态、临时交互和 mock API 数据绑定。
- 需要列表、卡片、详情、状态等业务形态数据时，优先配合 mock API 开发临时数据；所有新增 mock contract、service、model 和 wiring 都必须标记待开发审核。
- 不修改正式 ViewModel、正式 `AppPage` 导航、route parser、正式 API、正式 model、service setup、业务 manager、认证、埋点、推送或持久化逻辑。

## 工作流程

1. 先读项目结构：`lib/product_preview/`、相关页面的 `_page.dart`、已有 `widgets/`、相关 mock API 文件。
2. 判断任务类型：
   - 现有 UI 微调：只改展示层文件，事件仍绑定已有 ViewModel 方法。
   - 新页面或新流程原型：放到 `lib/product_preview/pages/<feature>/`，遵循正式页面命名和职责拆分，不要接入正式导航。
   - 需要数据：优先用 `$flutter-mvvm-mock-api-dev` 的 mock API 模式实现，并标记待开发审核；只有纯布局占位、没有 service 层价值的小型 UI 状态才保留在 preview-only ViewModel 中。
3. 做 UI 时复用现有组件、theme、间距、按钮和弹层风格。
4. 完成后输出审核说明：列出 PM 改动文件、待开发审核的 mock/API 文件、不得直接发布的预览页面。
5. 运行项目已有检查；通常是 `dart format lib test`、`flutter analyze`，能跑测试时运行相关 widget/mock 测试。

## 读取参考

- 修改现有 UI 或判断可改范围：读 `references/ui-scope.md`。
- 新增或注册 PM 预览页面：读 `references/product-preview-pattern.md`。
- 使用 mock 数据或新增 mock API：读 `references/mock-review-boundary.md`。

## 输出标准

- UI 改动不改变业务状态、异步流程、导航决策、API 调用或数据持久化。
- 新增 PM 页面全部隔离在 `lib/product_preview/`，正式 app 不通过业务导航直接进入它们。
- 首页悬浮入口仅打开产品预览，不承载业务逻辑。
- 数据驱动的 PM 预览优先复用或新增 mock API，不把业务形态列表/详情长期硬编码在预览 ViewModel 中。
- mock API 改动和 mock-only model 有清楚的 `PM preview / pending developer review` 标记。
- 开发可以根据预览页面审核、迁移和重写正式 ViewModel/API 接入。
