---
name: flutter-mvvm-feature-dev
description: >-
  在已有 Flutter MVVM 项目中开发正式页面、UI、共用组件、ViewModel、sealed AppPage 导航和弹层，或把已审核的 lib/product_preview/ 原型迁移为正式功能。用于修改可发布的页面行为和导航；不用于创建新项目、隔离预览原型，或开发数据层、API、mock service 和 model。
---

# Flutter MVVM Feature Dev

## 工作流程

1. 确认当前项目包含 `lib/app_container.dart`、`lib/mvvm/`、`lib/navigation/` 和 `lib/pages/`，并读取最相似的页面、ViewModel、AppPage 和 l10n 写法；当前目录不满足时停止并要求真实项目路径，不猜测或虚构目录。
2. 迁移预览原型时先读 `lib/product_preview/`，再按正式业务边界实现，不直接提升临时 mock 或 demo 逻辑。
3. 让 Widget 负责固定展示内容和事件绑定，让 ViewModel 负责状态、异步、导航、弹窗和业务动作。
4. 为可导航页面新增强类型 AppPage case；由 AppPage provider 延迟创建 ViewModel，并从 `AppContainer.shared` 取得 Service 或 Repository 后构造注入。
5. 复用项目已有组件、主题、间距、导航、loading/error 和弹层封装。
6. 格式化改动文件并运行 `flutter analyze`；纯展示改动不新增或修改测试；其余改动先检查已有测试是否直接断言受影响的输入、动作、状态、输出或 contract，仅执行到相关代码不算直接覆盖；覆盖充分时复跑并记录依据，覆盖不足时才新增或更新最小测试；混合改动只覆盖行为部分。

## 关键边界

- 新页面 ViewModel 使用 `<Feature>ViewModelInput`、`Output`、`Type` 和实现类；Page 接收返回非空 ViewModel 的 provider。
- 用户可见文案走 l10n；固定 Widget 文案直接读取 `AppLocalizations`，跨页面、弹层和 toast 的 `DisplayText` 参数用 `.localized` 延迟到展示时解析，服务端原文用 `.raw`。
- 仅依赖 l10n、Theme 或 BuildContext 的固定展示值由 Page/Widget 直接读取；不得为纯 l10n 透传新增 ViewModel Output。只有值依赖业务状态、异步结果、页面参数或用户操作时，才由 ViewModel 输出。
- 只有颜色、字体、间距、布局、圆角、阴影、图标或静态文案发生变化，且状态、callback、校验、交互、导航、弹层结果和异步行为全部不变时，才视为纯展示改动。
- Service 和 Repository 不新增 `shared`，业务依赖也不进入通用 MVVM 基类。
- 普通页面不预先创建 ViewModel；Alert、ActionSheet 和 child ViewModel 等特殊所有权按生命周期单独判断。
- 使用 sealed AppPage 和强类型参数，不引入 `enum + dynamic param`，也不绕过现有导航与 loading/error 封装。
- 共用组件保持展示型，通过 callback 暴露事件，不直接依赖业务 Service、具体 ViewModel 或页面路由。

## 读取参考

- 创建页面或 ViewModel：读 `references/page-pattern.md`；新增导航时同时读 `references/navigation-pattern.md`。
- 修改 UI、弹窗、ActionSheet 或 BottomSheet：读 `references/ui-change-pattern.md`。
- 抽取共用组件或整理 `widgets/`：读 `references/common-components.md`。
