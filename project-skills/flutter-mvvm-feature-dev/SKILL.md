---
name: flutter-mvvm-feature-dev
description: >-
  在已有 Flutter MVVM 项目中开发正式页面、组件、ViewModel、AppPage 导航和弹层，或迁移已审核的预览页面。不创建新项目或隔离原型，不开发 API、Mock 和数据模型。
---

# 正式页面开发

## 开始前

- 确认项目有 `lib/app_container.dart`、`lib/mvvm/`、`lib/navigation/` 和 `lib/pages/`。当前目录不对时停止，说明需要真实项目路径，不猜目录。
- 读相似页面、ViewModel、AppPage 和 l10n 写法。没有相似页面时，先查框架真实接口。
- 新增页面、改行为、调依赖或迁移原型前，读[文件职责](../shared-references/architecture-responsibilities.md)。纯样式或固定文案修改不用重复读。
- 迁移原型时先看 `lib/product_preview/`，再按正式功能实现。不直接把临时 Mock 或 demo 逻辑搬进正式代码。

## 页面怎么写

- Widget 负责展示、绑定事件，以及 controller、焦点、滚动和动画的生命周期。
- ViewModel 负责页面状态、异步操作、导航和弹窗。共享数据和独立业务规则调用注入的 Repository、Model 或业务 Service。
- 新 ViewModel 使用 `<Feature>ViewModelInput`、`Output`、`Type` 和实现类。
- Page 接收返回非空 ViewModel 的 provider。普通页面的 ViewModel 由 AppPage provider 延迟创建。
- AppPage provider 从 `AppContainer.shared` 取得依赖，再通过构造函数传给 ViewModel。
- Alert、ActionSheet 和子 ViewModel 可以有不同的创建方式，但要明确由谁初始化和释放。

## 事件与输出

- 按 `View → Input → VM → Output → View` 传递事件和状态。
- Input 默认返回 `void`，只接收事件。异步工作和顺序等待放在 VM 私有方法里。
- 状态、结果、完成通知和错误通过 Output 或已有输出通道返回。View 不等待 Input 的返回值来决定下一步。
- 只有框架要求异步返回时可以例外，例如 `RefreshIndicator.onRefresh`。在接口处说明原因，不为测试方便让普通 Input 返回 Future。

## 复用已有能力

- 复用已有组件、主题、间距、导航、loading/error 和弹层封装。
- 路由使用 sealed AppPage 和强类型参数，不用 `enum + dynamic param`。
- 共用组件只负责展示，通过 callback 传出事件，不依赖业务 Service、具体 ViewModel 或页面路由。
- App 配置应用，AppContainer 组装共享依赖，AppPage 构造页面。不要把页面流程放进这些入口。
- Service 和 Repository 不加 `shared`，通用 MVVM 基类不加业务依赖。

## 文案

- 用户可见文案走 l10n。
- 固定文案、Theme 和依赖 Context 的展示值由 Page/Widget 直接读取，不加纯转发的 VM Output。
- 依赖业务状态、异步结果、页面参数或用户操作的值，由 VM 输出。
- 跨页面、弹层和 toast 的 `DisplayText` 使用 `.localized`，展示时再解析。服务端原文用 `.raw`。

## 完成检查

- 检查本次文件职责、数据归属和依赖方向，修正相关问题。
- 格式化改动文件，运行 `flutter analyze`。
- 只有颜色、字体、间距、布局、圆角、阴影、图标或静态文案变化，才可能算纯展示。状态、callback、校验、交互、导航、弹层结果和异步行为必须都没变。
- 纯展示改动看实际界面，不新增或修改测试，也不写只检查控件存在的测试。
- 行为改动优先测试 ViewModel。先看已有测试是否直接检查了受影响的输入、动作、状态、输出或接口约定。只是执行到代码不算覆盖。
- 已覆盖就复跑并说明依据；没覆盖才补最小测试。混合改动只测试行为部分。
- 默认不新增 Page/Widget 测试。重要 UI 交互无法在逻辑层验证时才例外。

## 按需阅读

- 创建页面或修改 ViewModel：读 [页面模式](references/page-pattern.md)。
- 修改导航调用或绑定：再读 [导航模式](references/navigation-pattern.md)。
- 修改 UI 或弹层：读 [UI 修改](references/ui-change-pattern.md)。
- 抽取组件或整理 `widgets/`：读 [共用组件](references/common-components.md)。
