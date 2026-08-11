# 页面和 ViewModel 模式

## 先读相邻实现

新增或修改页面前，读取 1～2 个相似页面及其：

- `<feature>_page.dart` 与 `<feature>_view_model.dart`
- 对应 AppPage case
- 相关 Widget、l10n key 和已有测试

项目代码优先于本参考。保持相邻页面的基类、命名、import 和状态管理方式。

## 文件与类型

- 页面目录和文件使用 snake_case，例如 `lib/pages/profile/profile_page.dart`。
- 类型命名为 `<Feature>Page`、`<Feature>ViewModelInput`、`Output`、`Type` 和 `<Feature>ViewModel`。
- ViewModel Page 使用项目的 `AppBaseStatefulPage<T>` 与对应 State，即使页面没有本地 controller 或 animation。

## ViewModel 职责

- input 表达用户或生命周期事件，并跟随项目已有 `onClickXxx`、`onInputXxx` 等命名。
- output 暴露依赖业务状态、异步结果、页面参数或用户操作的展示状态；默认使用 getter 配合 `makeRebuild()`。
- 仅为输入联动、进度、倒计时、刷新或一次性 UI 事件等局部高频状态使用 `ValueStream<T>`/`Stream<T>`。
- 内部状态保持私有；异步 loading/error 使用项目现有 tracker。
- 导航、弹窗和业务动作由 ViewModel 发起，Widget 只绑定事件。

## 展示值归属

- 新增 ViewModel Output 前先识别值的依赖，不因相邻页面已有同名 Output 就直接照搬。
- 仅依赖 l10n、Theme 或 BuildContext 的固定文案和样式由 Page/Widget 直接读取。
- 不得为单纯返回固定 l10n 文案的值新增 ViewModel Output、接口 getter 或实现 getter。
- 仅当值依赖业务状态、异步结果、页面参数或用户操作时，才作为 ViewModel Output。

固定页面标题直接留在 Page：

```dart
title: Text(strings.dragDropEditTitle),
```

不要为它新增纯透传：

```dart
DisplayText get title => .localized((strings) => strings.dragDropEditTitle);
```

## Page 与依赖

- Page 只依赖 `<Feature>ViewModelType>`，并显式接收返回非空 ViewModel 的 `viewModelProvider`。
- 普通页面由对应 AppPage provider 延迟创建 ViewModel；Page 不自行创建，也不接收预先创建的普通页面实例。
- ViewModel 通过构造函数接收 Service 或 Repository；AppPage provider 从 `AppContainer.shared` 取得依赖。
- Alert、ActionSheet 和 child ViewModel 可能需要预配置实例；修改前确认创建、绑定和释放责任，不套用普通页面所有权。

## 本地化

- 用户可见文案写入项目现有 ARB，并遵循当前 key 命名。
- Page 或纯 Widget 用 `AppLocalizations.of(context)!` 读取展示文案。
- ViewModel 传递给 toast、Alert、InputAlert 或 ActionSheet 的 `DisplayText` 参数使用 `.localized((strings) => strings.xxx)`，由展示端按当前语言解析。
- API 和服务端返回的原始展示字符串使用 `.raw(value)`；raw 分支不会读取 `AppLocalizations` 或建立本地化依赖。
- ViewModel 不持有 `BuildContext`，也不直接读取 `AppLocalizations`；需要结合业务状态或参数的展示文案同样通过 `.localized(...)` 闭包延迟计算。

```dart
final alert = AlertViewModel(
  title: .localized((strings) => strings.deleteTitle),
  content: .raw(serverMessage),
);
```
