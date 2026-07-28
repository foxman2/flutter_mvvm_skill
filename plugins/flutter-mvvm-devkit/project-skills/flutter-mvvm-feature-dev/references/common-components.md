# 共用组件规划

## 按复用范围放置

- 单个页面使用：放在 `pages/<feature>/widgets/`。
- 同一业务域多个页面使用：放在业务域的 `widgets/`。
- 跨业务域复用且不依赖业务模型：放在 `lib/widgets/`。
- 颜色、字体、间距、圆角和 Theme 扩展：放在项目现有 theme 目录。

项目已有其他组织方式时跟随现状，不为套模板搬目录。

## 抽取时机

只有重复结构的语义和参数已经稳定，或独立单元能显著改善命名、复用和测试边界时才抽取。不要为假设中的未来复用预先增加大量可选参数。

## 组件边界

共用组件保持展示型，可以接收：

- 文案、图标、颜色、状态和简单 view data
- `VoidCallback`、`ValueChanged<T>` 等事件回调

不要直接依赖：

- `AppContainer` 或业务 Service
- 具体业务 ViewModel
- AppPage 或 Navigator
- Firebase、推送、埋点等产品服务

业务动作留在 ViewModel，组件通过 callback 暴露事件。用户可见文案继续走 l10n。

提升到全局组件前确认它确实跨页面复用、参数少而稳定，并使用项目已有 theme 与交互风格。
