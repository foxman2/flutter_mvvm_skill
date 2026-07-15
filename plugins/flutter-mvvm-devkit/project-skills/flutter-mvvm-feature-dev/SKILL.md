---
name: flutter-mvvm-feature-dev
description: >-
  用于已有 flutter-mvvm-template 架构项目中的正式功能开发：创建或修改正式页面、UI、共用组件、ViewModel、sealed AppPage 导航、弹窗、ActionSheet、BottomSheet，以及将 lib/product_preview/ 中已审核的隔离预览迁移为正式页面。不用于隔离预览原型创建；使用 flutter-mvvm-pm-ui。不用于创建新项目；使用 flutter-mvvm-template。不用于纯数据层 API/model 开发；已确认后端 API 使用 flutter-mvvm-api-dev，后端未确认或 mock API 使用 flutter-mvvm-mock-api-dev。
---

# Flutter MVVM Feature Dev

使用这个 skill 在已有 Flutter MVVM 项目里做日常开发：创建页面、修改 UI、补 ViewModel、接导航、处理弹窗和底部弹层。

## 职责边界

- 只处理已有项目里的页面、UI、组件、导航和 ViewModel 侧工作。
- 负责把审核通过的 `lib/product_preview/` 隔离原型迁移为正式 `lib/pages/<feature>/`、ViewModel 和 `AppPage`。
- 可以把 ViewModel 接到已有 API 方法，但不负责新增正式 API service 或 mock service。
- 当前项目应包含 `lib/mvvm/`、`lib/navigation/`、`lib/pages/`，并使用 `sealed class AppPage` 表达页面路由。

## 工作流程

1. 先读当前项目结构：`pubspec.yaml`、`lib/l10n/`、`lib/mvvm/`、`lib/navigation/app_page.dart`、`lib/navigation/app_navigator.dart`、`lib/pages/`。
2. 找一个最相似的已有页面和 ViewModel，优先复制它的组织方式、命名、状态管理和 UI 风格。
3. 如果任务来自隔离预览，先读 `lib/product_preview/` 的原型，再重新按正式 MVVM 边界实现，不直接把原型当最终业务代码搬过去。
4. 创建或修改页面时保持职责分离：Widget 负责展示和事件绑定，ViewModel 负责状态、异步、导航、弹窗和业务动作；新增页面 ViewModel 必须拆成 input/output/type/实现类。
5. 新增可跳转页面时，在 `AppPage` 中新增具体 page case，不使用 `dynamic param` 或全局 enum 参数。
6. 修改 UI 或抽取组件时优先使用项目已有组件、主题、间距、按钮样式和弹层容器。
7. 完成后格式化本次改动文件并运行 `flutter analyze`；先运行覆盖受影响行为的已有测试。
8. 只为非平凡状态转换、关键交互或回归问题新增针对性测试；不要因为项目存在 `test/` 目录、改动文件较多或新增了页面就机械补测试。交付时说明新增测试对应的风险，或说明本次无需新增测试的理由。

## 读取参考

- 创建新页面或 ViewModel：读 `references/page-pattern.md`。
- 接入 sealed page 导航或路由参数：读 `references/navigation-pattern.md`。
- 修改 UI、弹窗、ActionSheet、BottomSheet：读 `references/ui-change-pattern.md`。
- 规划或抽取共用组件、整理 `widgets/` 目录：读 `references/common-components.md`。

## 开发约定

- 页面目录使用 snake_case：`lib/pages/profile/`。
- 页面文件命名为 `<feature>_page.dart`，ViewModel 文件命名为 `<feature>_view_model.dart`。
- 页面类命名为 `<Feature>Page`，ViewModel 类命名为 `<Feature>ViewModel`。
- ViewModel 契约命名为 `<Feature>ViewModelInput`、`<Feature>ViewModelOutput`、`<Feature>ViewModelType`。
- Page 泛型使用 `<Feature>ViewModelType`，并显式声明 `required super.viewModelProvider`；provider 可以为 `null`，但非空 provider 必须返回非空 ViewModel。
- 只有无参数、无外部依赖的 ViewModel 才通过 `defaultViewModel()` 创建，调用方仍显式传 `viewModelProvider: null`。
- ViewModel 需要参数或依赖时，由 `AppPage.generateWidgetBuilder()` 传入 provider 闭包延迟创建；普通页面不要先创建 ViewModel 实例再捕获或传入 Page。
- input 方法只描述用户事件：点击用简短 `onClickXxx`，输入用 `onInputXxx`；业务目的放到实现类私有方法里。
- output 默认使用 getter + `makeRebuild()`；高频或局部刷新状态才使用 `ValueStream<T>`/`Stream<T>`。
- 用户可见文案必须走 l10n。新增文案先写入 `lib/l10n/app_en.arb`；当前模板默认只支持英语。
- Page 或纯 Widget 展示文案用 `AppLocalizations.of(context)!`；ViewModel 里的弹窗、toast、导航结果文案和 output getter 用 `localStrings`。
- 不在 ViewModel 构造函数或 `initState()` 里读取 `localStrings`，因为本地化 callback 由页面绑定后提供。
- 页面 case 命名为 `<Feature>AppPage`，参数放在构造器中并保持强类型。
- 普通页面默认 `AppPageTransition.push`；弹窗使用 `alert`；操作面板使用 `actionSheet`；底部弹层使用 `bottomSheet` 或 `bottomSheetWithNavigator`。
- 不把业务服务、API client、Firebase、推送、本地化生成逻辑塞进通用 MVVM 基类。
- 不把隔离预览页面留在正式导航里；迁移后保持 `lib/product_preview/` 和正式页面职责分开。
- 不绕过现有 `show()`、`pushReplacement()`、`pushAndRemoveUntil()`、`replaceRoot()`、`pop()`、`loadingTracker`、`errorTracker` 等封装。
- 不在 input 接口里使用裸的 `show/open/load/save/delete/submit/close/select/fetch` 这类目的性方法名；点击 Delete 或 Submit 这类 UI 文案时写 `onClickDelete()`、`onClickSubmit()`。
- 不把 `ValueNotifier` 作为页面 ViewModel output；输入联动、进度、倒计时、刷新状态和一次性 UI 事件使用 `ValueStream<T>` 或 `Stream<T>`。
- 共用组件保持展示型，通过 callback 暴露事件，不直接依赖业务服务、具体 ViewModel 或页面路由。
- child ViewModel、Alert、ActionSheet 等场景先确认创建者、页面绑定和释放责任；允许为动作配置或父子协作保留已创建实例，不机械改成普通页面的延迟工厂。

## 输出标准

- 代码看起来像项目里原本就有的：目录、命名、import 顺序、构造参数和 provider 组装位置都和相邻页面一致。
- 新页面可以从 ViewModel 发起导航和弹窗，不在 Widget 里直接堆业务流程。
- routeName 稳定、语义清楚；只有项目实际接入深链或字符串路由恢复时才创建并同步 parser。
- UI 修改不破坏现有交互、返回行为、loading/error 展示和测试。
- 新抽取的组件有清楚的复用半径：局部组件留在 feature 内，跨页面且不依赖业务模型的组件才进入 `lib/widgets/`。
- 测试只覆盖本次变更的重要行为风险；纯布局、文案、样式和可由编译器或 analyzer 约束的结构默认不新增测试。
