# 共用组件规划

## 目录建议

按“层级 + 复用半径”规划组件，不要一开始就把所有 UI 都抽到全局。

```text
lib/
├── theme/
│   ├── app_theme.dart
│   ├── app_colors.dart
│   ├── app_spacing.dart
│   └── text_styles.dart
├── widgets/
│   ├── layout/
│   ├── buttons/
│   ├── feedback/
│   ├── form/
│   └── dialog/
└── pages/
    └── profile/
        ├── profile_page.dart
        ├── profile_view_model.dart
        └── widgets/
```

如果项目已有其他目录命名，优先跟随项目现状，不为了套模板强行搬家。

## 放置规则

- 只被一个页面使用：放在 `pages/<feature>/widgets/`。
- 被同一业务域多个页面使用：放在业务域目录下，例如 `pages/order/widgets/`。
- 被多个业务域复用，且不依赖业务模型：放到 `lib/widgets/`。
- 颜色、字体、间距、圆角、Theme 扩展：放到 `lib/theme/` 或项目已有 theme 目录。
- 导航、弹窗展示方式、BottomSheet 容器：优先放在 `navigation/` 或 `widgets/layout/`，不要散落在页面里。

## 抽取时机

使用“三次规则”：

1. 第一次出现时，先写在页面里。
2. 第二次出现相似结构时，抽成 feature 内局部组件。
3. 第三次跨业务复用且语义稳定时，再提升到 `lib/widgets/`。

不要为了“以后可能复用”提前抽象。过早抽取通常会制造很多可选参数，让组件难以理解和测试。

## MVVM 边界

共用组件尽量保持展示型：

```dart
AppEmptyView(
  title: strings.emptyTitle,
  actionTitle: strings.refreshAction,
  onActionPressed: viewModel.onClickReload,
)
```

组件可以接收：

- 文案、图标、颜色、状态。
- `VoidCallback`、`ValueChanged<T>` 等事件回调。
- 简单展示数据或专用 view data。

组件不要直接依赖：

- `AppContainer` 或其持有的 App 级依赖。
- 具体业务 ViewModel。
- `AppPage` case 或 `Navigator` 跳转。
- Firebase、推送、分析埋点等产品服务。

业务动作放在 ViewModel 中，组件只通过 callback 暴露事件。

传给组件的用户可见文案也走 l10n：Page 中用 `AppLocalizations.of(context)!` 取纯展示文案，ViewModel 中用 `localStrings` 取状态和动作文案。

## 常见分类

`widgets/layout/`：

- 页面基础容器。
- SafeArea 或键盘适配容器。
- BottomSheet 容器。
- 通用 section/header/footer。

`widgets/buttons/`：

- 主要按钮、次要按钮。
- 底部固定操作按钮。
- icon button wrapper。

`widgets/feedback/`：

- Empty view。
- Error view。
- Loading skeleton。
- Retry panel。

`widgets/form/`：

- 输入框外壳。
- 表单项布局。
- picker 入口。
- 表单错误提示。

`widgets/dialog/`：

- 通用弹窗外观。
- 弹窗内容布局。
- Alert/action sheet 的可复用子组件。

## 设计检查

抽取组件前先问：

- 这个组件是否真的跨页面复用？
- 它是否依赖业务模型？如果依赖，是否应该留在 feature 内？
- 参数是否少而稳定？如果需要很多布尔参数，可能还没到抽象时机。
- callback 是否足够表达事件，而不是把业务流程塞进组件？
- 组件是否使用项目已有 theme、spacing 和 widget 风格？

## 与现有模板的关系

`CommonBottomSheetContainer` 适合留在全局 `widgets/`，因为它是跨页面展示基础设施。

`AlertPage`、`InputAlertPage`、`ActionSheetPage` 更像通用页面能力，可以继续放在 `pages/alert`、`pages/input_alert`、`pages/action_sheet`，通过对应 `AppPage` 统一调起。
