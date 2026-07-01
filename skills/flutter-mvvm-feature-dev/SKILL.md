---
name: flutter-mvvm-feature-dev
description: 在已有 Flutter MVVM 项目中开发功能页面、修改 UI、创建 ViewModel、接入 sealed AppPage 导航、弹窗、ActionSheet 和 BottomSheet。Use when working inside an existing Flutter app that follows the flutter-mvvm-template architecture and needs page creation, UI changes, route wiring, or ViewModel updates.
---

# Flutter MVVM Feature Dev

使用这个 skill 在已有 Flutter MVVM 项目里做日常开发：创建页面、修改 UI、补 ViewModel、接导航、处理弹窗和底部弹层。

## 适用场景

- 用户要求“创建一个页面”“新增功能页”“改一下这个页面 UI”“接一个跳转”“加弹窗/ActionSheet/BottomSheet”。
- 当前项目包含 `lib/mvvm/`、`lib/navigation/`、`lib/pages/`，并使用 `sealed class AppPage` 表达页面路由。
- 用户希望 AI 按当前项目 MVVM 写法继续开发，而不是重新生成项目模板。

如果用户要从零创建新 Flutter MVVM 项目，使用 `$flutter-mvvm-template`，不要使用这个 skill。

## 工作流程

1. 先读当前项目结构：`pubspec.yaml`、`lib/mvvm/`、`lib/navigation/app_page.dart`、`lib/navigation/app_navigator.dart`、`lib/pages/`。
2. 找一个最相似的已有页面和 ViewModel，优先复制它的组织方式、命名、状态管理和 UI 风格。
3. 创建或修改页面时保持职责分离：Widget 负责展示和事件绑定，ViewModel 负责状态、异步、导航、弹窗和业务动作。
4. 新增可跳转页面时，在 `AppPage` 中新增具体 page case，不使用 `dynamic param` 或全局 enum 参数。
5. 修改 UI 时优先使用项目已有组件、主题、间距、按钮样式和弹层容器。
6. 完成后运行项目已有检查；通常是 `dart format lib test`、`flutter analyze`，有相关测试时运行或补充测试。

## 读取参考

- 创建新页面或 ViewModel：读 `references/page-pattern.md`。
- 接入 sealed page 导航或路由参数：读 `references/navigation-pattern.md`。
- 修改 UI、弹窗、ActionSheet、BottomSheet：读 `references/ui-change-pattern.md`。

## 开发约定

- 页面目录使用 snake_case：`lib/pages/profile/`。
- 页面文件命名为 `<feature>_page.dart`，ViewModel 文件命名为 `<feature>_view_model.dart`。
- 页面类命名为 `<Feature>Page`，ViewModel 类命名为 `<Feature>ViewModel`。
- 页面 case 命名为 `<Feature>AppPage`，参数放在构造器中并保持强类型。
- 普通页面默认 `AppPageTransition.push`；弹窗使用 `alert`；操作面板使用 `actionSheet`；底部弹层使用 `bottomSheet` 或 `bottomSheetWithNavigator`。
- 不把业务服务、API client、Firebase、推送、本地化生成逻辑塞进通用 MVVM 基类。
- 不绕过现有 `show()`、`pushReplacement()`、`pop()`、`loadingTracker`、`errorTracker` 等封装。

## 输出标准

- 代码看起来像项目里原本就有的：目录、命名、import 顺序、构造参数、默认 provider 都和相邻页面一致。
- 新页面可以从 ViewModel 发起导航和弹窗，不在 Widget 里直接堆业务流程。
- routeName 稳定、语义清楚，并且需要深链或解析时同步更新 parser。
- UI 修改不破坏现有交互、返回行为、loading/error 展示和测试。
