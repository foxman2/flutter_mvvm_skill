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
      viewModelProvider: () => ProfileViewModel(
        userId: userId,
        userRepository: AppContainer.shared.userRepository,
      ),
    );
  }
}
```

provider 在 Page 初始化时才执行。普通页面无论是否包含路由参数，都在对应
`AppPage` 中组合并传入非空 provider。ViewModel 使用 App 级依赖时，通过构造函数
接收 AppPage 从 `AppContainer.shared` 取得的具体 Service 或 Repository。不要先创建
普通页面的 ViewModel 实例再传给 Page；Alert、ActionSheet、child ViewModel 等需要
预配置或共享实例的特殊所有权场景应单独判断生命周期。

没有页面运行参数时也由 AppPage 组装：

```dart
@override
WidgetBuilder generateWidgetBuilder() {
  return (_) => HomePage(
    viewModelProvider: () => HomeViewModel(),
  );
}
```

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
