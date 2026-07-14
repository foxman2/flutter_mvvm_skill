# Sealed AppPage 导航模式

## 核心原则

页面导航使用具体 `AppPage` 子类表达，不使用 `enum + dynamic param`。

每个可导航页面都应该自己持有：

- `routeName`
- `defaultTransition`
- `queryParameters`，仅当需要路由字符串或深链参数时添加
- `generateWidgetBuilder()`
- 强类型构造参数

## 新增普通页面

```dart
final class ProfileAppPage extends AppPage {
  const ProfileAppPage({required this.userId});

  final String userId;

  @override
  String get routeName => '/profile';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.push;

  @override
  Map<String, String> get queryParameters => {'userId': userId};

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => ProfilePage(
      userId: userId,
      viewModelProvider: () => ProfileViewModel(userId: userId),
    );
  }
}
```

provider 闭包只在 Page 初始化 ViewModel 时执行。带参数或依赖的普通页面应在这里
延迟组装，不要在 `generateWidgetBuilder()` 外提前创建实例再传给 Page。无参数、
无外部依赖且覆盖了 `defaultViewModel()` 的页面则显式传
`viewModelProvider: null`。

ViewModel 中调用：

```dart
show(ProfileAppPage(userId: userId));
```

需要清空导航栈时调用 `replaceRoot(...)`；不要把它作为 `AppPageTransition`。

## 新增弹窗或弹层

Alert：

```dart
final class ConfirmDeleteAppPage extends AppPage {
  const ConfirmDeleteAppPage(this.viewModel);

  final ConfirmDeleteViewModelType viewModel;

  @override
  String get routeName => '/confirm-delete';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.alert;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => ConfirmDeletePage(viewModelProvider: () => viewModel);
  }
}
```

这里保留已创建的 `ConfirmDeleteViewModelType` 是特殊所有权：调用方需要先为弹窗
配置动作或结果回调，弹窗 Page 随后负责绑定并在退出时释放它。ActionSheet、child
ViewModel 等类似场景也要先检查生命周期；不能把这个例外推广到普通参数化页面，
也不能机械改写已有所有权链路。

BottomSheet：

```dart
final class FilterSheetAppPage extends AppPage
    implements BottomSheetConfigProvider {
  const FilterSheetAppPage();

  @override
  String get routeName => '/filter-sheet';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.bottomSheet;

  @override
  BottomSheetConfig get bottomSheetConfig =>
      const BottomSheetConfig(height: 360);

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => const FilterSheetPage();
  }
}
```

## Route parser

如果页面需要从字符串路由恢复，更新 `AppRouteParser`：

```dart
static AppPage? parse(String routeString) {
  final uri = Uri.parse(routeString);
  switch (uri.path) {
    case '/profile':
      final userId = uri.queryParameters['userId'];
      return userId == null ? null : ProfileAppPage(userId: userId);
    default:
      return null;
  }
}
```

不需要深链、浏览器地址或恢复路由时，不要为了形式主义添加 parser 分支。

## 命名和稳定性

- routeName 使用短横线或普通路径风格：`/profile-detail`。
- 页面改名时尽量不改 routeName，避免破坏外部跳转。
- transition 放在 page case 附近，让页面展示方式和页面定义一起维护。
- 不在 Widget 里直接 `Navigator.push`，除非项目当前局部代码已经这样做且没有 ViewModel 入口。
