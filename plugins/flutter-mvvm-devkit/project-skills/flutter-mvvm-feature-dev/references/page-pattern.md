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
- 独立路由页面由对应 AppPage provider 延迟创建 ViewModel；Page 不自行创建 ViewModel，也不接收预先创建的页面实例。
- ViewModel 通过构造函数接收 Service 或 Repository；AppPage provider 从 `AppContainer.shared` 取得依赖。
- Alert 和 ActionSheet 等特殊场景可能需要预配置实例；修改前确认创建、绑定和释放责任，不套用独立路由页面的所有权。

## 父页面组合子 Page

- 页面是否被嵌套不改变其 Page 类型。由父页面组合的子 Page 仍优先使用普通 `AppBaseStatefulPage<T>` 与对应 State。
- ViewModel 的创建者、持有者和生命周期所有者可以不同，但责任必须明确，且只能有一个生命周期所有者。
- 父级可以创建并持有稳定的子 ViewModel，再通过 `viewModelProvider` 交给子 Page。
- 当子 Page 是生命周期所有者时，由子 Page 负责 ViewModel 的初始化、绑定和释放；父级不得重复调用 ViewModel 的 `initState()` 或 `dispose()`。
- 父子页面通过明确的状态、回调或合同协调；不因嵌套关系新增另一套 Page 基类、专用绑定组件，或修改通用 MVVM Base。
- 同一次子 Page 生命周期内，provider 返回稳定且有效的实例。子 Page 重新挂载时，provider 不得返回已被释放的实例。

父级创建和持有实例、子 Page 拥有其生命周期时，最小 provider 写法如下：

```dart
late final ChildViewModelType _childViewModel;

@override
void initState() {
  super.initState();
  _childViewModel = ChildViewModel();
}

@override
Widget build(BuildContext context) {
  return ChildPage(
    viewModelProvider: () => _childViewModel,
  );
}
```

容器形式、是否保留 State、是否条件挂载，以及实例在重新挂载时如何更新，均由具体功能需求决定；本 skill 只规定职责和生命周期边界，不规定 Widget 结构或状态保留策略。

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
