---
name: flutter-mvvm-feature-dev
description: >-
  在已有 Flutter MVVM 项目中开发正式功能页面、修改 UI、规划和抽取共用组件、创建或修改 ViewModel、接入 sealed AppPage 导航、弹窗、ActionSheet 和 BottomSheet。Use when an existing app follows the flutter-mvvm-template architecture and the task is formal page/UI/navigation/component/ViewModel work, including reviewing and migrating approved PM preview pages from lib/product_preview/ into production pages. Do not use for product-manager-only prototype or UI preview work; use flutter-mvvm-pm-ui. Do not use to create a new project; use flutter-mvvm-template. Do not use for data-layer-only API/model work; use flutter-mvvm-api-dev for confirmed backend APIs and flutter-mvvm-mock-api-dev for backend-unconfirmed mock APIs.
---

# Flutter MVVM Feature Dev

使用这个 skill 在已有 Flutter MVVM 项目里做日常开发：创建页面、修改 UI、补 ViewModel、接导航、处理弹窗和底部弹层。

## 职责边界

- 只处理已有项目里的页面、UI、组件、导航和 ViewModel 侧工作。
- 负责把审核通过的 `lib/product_preview/` PM 原型迁移为正式 `lib/pages/<feature>/`、ViewModel 和 `AppPage`。
- 可以把 ViewModel 接到已有 API 方法，但不负责新增正式 API service 或 mock service。
- 当前项目应包含 `lib/mvvm/`、`lib/navigation/`、`lib/pages/`，并使用 `sealed class AppPage` 表达页面路由。

## 工作流程

1. 先读当前项目结构：`pubspec.yaml`、`lib/mvvm/`、`lib/navigation/app_page.dart`、`lib/navigation/app_navigator.dart`、`lib/pages/`。
2. 找一个最相似的已有页面和 ViewModel，优先复制它的组织方式、命名、状态管理和 UI 风格。
3. 如果任务来自 PM 预览，先读 `lib/product_preview/` 的原型，再重新按正式 MVVM 边界实现，不直接把原型当最终业务代码搬过去。
4. 创建或修改页面时保持职责分离：Widget 负责展示和事件绑定，ViewModel 负责状态、异步、导航、弹窗和业务动作。
5. 新增可跳转页面时，在 `AppPage` 中新增具体 page case，不使用 `dynamic param` 或全局 enum 参数。
6. 修改 UI 或抽取组件时优先使用项目已有组件、主题、间距、按钮样式和弹层容器。
7. 完成后运行项目已有检查；通常是 `dart format lib test`、`flutter analyze`，有相关测试时运行或补充测试。

## 读取参考

- 创建新页面或 ViewModel：读 `references/page-pattern.md`。
- 接入 sealed page 导航或路由参数：读 `references/navigation-pattern.md`。
- 修改 UI、弹窗、ActionSheet、BottomSheet：读 `references/ui-change-pattern.md`。
- 规划或抽取共用组件、整理 `widgets/` 目录：读 `references/common-components.md`。

## 开发约定

- 页面目录使用 snake_case：`lib/pages/profile/`。
- 页面文件命名为 `<feature>_page.dart`，ViewModel 文件命名为 `<feature>_view_model.dart`。
- 页面类命名为 `<Feature>Page`，ViewModel 类命名为 `<Feature>ViewModel`。
- 页面 case 命名为 `<Feature>AppPage`，参数放在构造器中并保持强类型。
- 普通页面默认 `AppPageTransition.push`；弹窗使用 `alert`；操作面板使用 `actionSheet`；底部弹层使用 `bottomSheet` 或 `bottomSheetWithNavigator`。
- 不把业务服务、API client、Firebase、推送、本地化生成逻辑塞进通用 MVVM 基类。
- 不把 PM 预览页面留在正式导航里；迁移后保持 `lib/product_preview/` 和正式页面职责分开。
- 不绕过现有 `show()`、`pushReplacement()`、`pop()`、`loadingTracker`、`errorTracker` 等封装。
- 共用组件保持展示型，通过 callback 暴露事件，不直接依赖业务服务、具体 ViewModel 或页面路由。

## 输出标准

- 代码看起来像项目里原本就有的：目录、命名、import 顺序、构造参数、默认 provider 都和相邻页面一致。
- 新页面可以从 ViewModel 发起导航和弹窗，不在 Widget 里直接堆业务流程。
- routeName 稳定、语义清楚，并且需要深链或解析时同步更新 parser。
- UI 修改不破坏现有交互、返回行为、loading/error 展示和测试。
- 新抽取的组件有清楚的复用半径：局部组件留在 feature 内，跨页面且不依赖业务模型的组件才进入 `lib/widgets/`。
