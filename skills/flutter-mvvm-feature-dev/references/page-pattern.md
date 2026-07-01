# 页面和 ViewModel 模式

## 开始前先观察

新增页面前，先读 1-2 个相似页面：

- `lib/pages/<feature>/<feature>_page.dart`
- `lib/pages/<feature>/<feature>_view_model.dart`
- 页面对应的 `AppPage` case
- 相关 widget 或测试

优先沿用已有页面的继承方式。如果项目同时有 stateless 和 stateful 基类，按需求选择：

- 页面只消费 ViewModel 并由 ViewModel 触发刷新：优先 `AppBaseStatelessPage<T>`。
- 页面需要本地 controller、animation、focus、tab 等生命周期对象：使用 `AppBaseStatefulPage<T>` 和对应 state。

## 推荐目录

```text
lib/pages/profile/
├── profile_page.dart
└── profile_view_model.dart
```

## ViewModel 写法

ViewModel 继承 `AppBaseViewModel`，把页面动作放成方法：

```dart
class ProfileViewModel extends AppBaseViewModel {
  ProfileViewModel({required this.userId});

  final String userId;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    await Future<void>.delayed(Duration.zero)
        .trackLoadingAndConsumeError(this);
    makeRebuild();
  }

  void close() {
    pop();
  }
}
```

约定：

- 异步 loading 和错误处理优先走 `trackLoadingAndConsumeError(this)`。
- ViewModel 状态变化后调用 `makeRebuild()`，不要从外部直接拿 `State`。
- 页面跳转用 `show(...)`、`pushReplacement(...)`、`pushAndRemoveUntil(...)`。
- 关闭页面用 `pop(...)`、`popUseRoot(...)` 或项目已有封装。

## Page 写法

```dart
class ProfilePage extends AppBaseStatelessPage<ProfileViewModel> {
  const ProfilePage({
    super.key,
    required this.userId,
    ProfileViewModel? viewModel,
  }) : _viewModel = viewModel,
       super(viewModelProvider: _defaultProvider);

  final String userId;
  final ProfileViewModel? _viewModel;

  static ProfileViewModel? _defaultProvider() => null;

  @override
  ProfileViewModel? defaultViewModel() {
    return _viewModel ?? ProfileViewModel(userId: userId);
  }

  @override
  Widget createWidget(BuildContext context, ProfileViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const SizedBox.shrink(),
    );
  }
}
```

如果现有项目页面不使用可注入 `viewModel` 参数，就跟随项目现有写法，不强行引入。

## 测试

有测试目录时，优先补充轻量测试：

- ViewModel 方法是否触发预期状态。
- `AppPage` 的 `routeName`、`defaultTransition` 是否正确。
- 关键页面是否能 `pumpWidget`。
