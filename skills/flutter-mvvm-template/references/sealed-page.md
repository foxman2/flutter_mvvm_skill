# Sealed Page 模式

使用 Dart `sealed class` 表达带关联值的页面枚举，用它替代 `enum Page + dynamic param`。

## 基础契约

```dart
sealed class AppPage {
  const AppPage();

  String get routeName;
  AppPageTransition get defaultTransition;
  Map<String, String> get queryParameters => {};
  WidgetBuilder generateWidgetBuilder();
}
```

## 带参数的页面

```dart
final class ProfileAppPage extends AppPage {
  const ProfileAppPage({required this.userId});

  final String userId;

  @override
  String get routeName => '/profile';

  @override
  Map<String, String> get queryParameters => {'userId': userId};

  @override
  AppPageTransition get defaultTransition => AppPageTransition.push;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => ProfilePage(
      userId: userId,
      viewModelProvider: () => ProfileViewModel(userId: userId),
    );
  }
}
```

provider 在 Page 初始化时才执行。不要先创建普通页面的 ViewModel 实例再传给
Page；无页面运行参数并由 `defaultViewModel()` 创建的页面显式传
`viewModelProvider: null`。App 级依赖从 `AppContainer.shared` 获取，不作为路由、
Page 或 ViewModel 构造参数传递。Alert、ActionSheet、child ViewModel 等需要预配置或
共享实例的特殊所有权场景应单独判断生命周期。

## 调用方式

推荐：

```dart
show(ProfileAppPage(userId: userId));
show(AlertAppPage(alertViewModel));
replaceRoot(const HomeAppPage());
```

避免：

```dart
show(AppPage.profile, userId);
show(AppPage.alert, dynamicViewModel);
```

## 路由解析

不要把带参数页面强行塞进 `values` 列表。使用显式 parser：

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

## 命名

- 页面 case 命名为 `<Feature>AppPage`，避免和 widget 类名冲突。
- 项目演进期间保持 `routeName` 稳定。
- 构造参数保持强类型。
- transition 策略放在对应 page case 附近；清空导航栈用 `replaceRoot(...)`，不要把它放进 `AppPageTransition`。
