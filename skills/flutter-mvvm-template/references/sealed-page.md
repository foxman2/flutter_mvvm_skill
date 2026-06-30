# Sealed Page Pattern

Use Dart `sealed class` as a page enum with associated values. This replaces `enum Page + dynamic param`.

## Base Contract

```dart
sealed class AppPage {
  const AppPage();

  String get routeName;
  AppPageTransition get defaultTransition;
  Map<String, String> get queryParameters => {};
  WidgetBuilder generateWidgetBuilder();
}
```

## Parameterized Case

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
    return (_) => ProfilePage(viewModel: ProfileViewModel(userId));
  }
}
```

## Call Sites

Prefer:

```dart
show(ProfileAppPage(userId: userId));
show(AlertAppPage(alertViewModel));
```

Avoid:

```dart
show(AppPage.profile, userId);
show(AppPage.alert, dynamicViewModel);
```

## Route Parsing

Do not force parameterized pages into a `values` list. Use an explicit parser:

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

## Naming

- Name cases as `<Feature>AppPage` to avoid colliding with widget classes.
- Keep `routeName` stable during migrations.
- Keep constructor parameters strongly typed.
- Keep transition policy close to the page case.
