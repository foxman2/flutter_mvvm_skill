# 页面和 ViewModel 模式

## 开始前先观察

新增页面前，先读 1-2 个相似页面：

- `lib/pages/<feature>/<feature>_page.dart`
- `lib/pages/<feature>/<feature>_view_model.dart`
- 页面对应的 `AppPage` case
- 相关 widget 或测试
- `lib/l10n/app_en.arb` 中已有的文案命名方式

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

新增页面 ViewModel 必须拆成 input/output/type/实现类。Page 只依赖
`<Feature>ViewModelType`；事件方法放 input，展示状态放 output。

```dart
abstract class ProfileViewModelInput {
  void onClickClose();

  void onClickReload();
}

abstract class ProfileViewModelOutput {
  String get title;
}

abstract class ProfileViewModelType extends AppBaseViewModel
    implements ProfileViewModelInput, ProfileViewModelOutput {}

class ProfileViewModel extends ProfileViewModelType {
  ProfileViewModel({required this.userId});

  final String userId;
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void onClickClose() {
    pop();
  }

  @override
  void onClickReload() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await Future<void>.delayed(Duration.zero)
        .trackLoadingAndConsumeError(this);
    _profileName = 'Ada';
    makeRebuild();
  }

  @override
  String get title => _profileName ?? localStrings.profileTitle;
}
```

约定：

- input 方法只描述用户事件：点击用简短 `onClickXxx`，输入用 `onInputXxx`，不要默认加 `Button`、`Field`、`Tile` 等控件后缀。
- input 不使用裸的目的性方法名，例如 `show/open/load/save/delete/submit/close/select/fetch`；如果 UI 文案就是 Delete 或 Submit，写成 `onClickDelete()`、`onClickSubmit()`，业务目的放到实现类私有方法。
- `onPop` 这类系统生命周期事件可以保留，不属于 click/input 命名范围。
- 默认 output 使用 getter + `makeRebuild()`，普通展示状态不要为了形式主义做成 stream。
- 高频或局部刷新状态使用 `ValueStream<T>`/`Stream<T>`，例如输入框按钮 enabled、上传进度、倒计时、下拉刷新状态和一次性 UI 事件；页面用 `ValueStreamBuilder<T>`。
- 不把 `ValueNotifier` 作为页面 ViewModel output。
- ViewModel 内部状态保持私有，Page 不直接读写实现类字段。
- ViewModel 中的用户可见文案通过 `localStrings` 获取，包括弹窗、toast、ActionSheet、导航结果文案和 output getter。
- 不在 ViewModel 构造函数或 `initState()` 中读取 `localStrings`；如需初始文案，用 getter 在页面 build 时现取。
- 异步 loading 和错误处理优先走 `trackLoadingAndConsumeError(this)`。
- ViewModel 状态变化后调用 `makeRebuild()`，不要从外部直接拿 `State`。
- 页面跳转用 `show(...)`、`pushReplacement(...)`、`pushAndRemoveUntil(...)`。
- 关闭页面用 `pop(...)`、`popUseRoot(...)` 或项目已有封装。

## Page 写法

```dart
import '../../l10n/app_localizations.dart';

class ProfilePage extends AppBaseStatelessPage<ProfileViewModelType> {
  const ProfilePage({
    super.key,
    required this.userId,
    ProfileViewModelType? viewModel,
  }) : _viewModel = viewModel,
       super(viewModelProvider: _defaultProvider);

  final String userId;
  final ProfileViewModelType? _viewModel;

  static ProfileViewModelType? _defaultProvider() => null;

  @override
  ProfileViewModelType? defaultViewModel() {
    return _viewModel ?? ProfileViewModel(userId: userId);
  }

  @override
  Widget createWidget(BuildContext context, ProfileViewModelType viewModel) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(viewModel.title)),
      body: Center(child: Text(strings.profileDescription)),
    );
  }
}
```

如果现有项目页面不使用可注入 `viewModel` 参数，就跟随项目现有写法，不强行引入。

页面或纯 Widget 中只负责展示的文案直接用 `AppLocalizations.of(context)!`。需要由 ViewModel 发起的弹窗、toast、ActionSheet 和状态文案不要从 Widget 传字符串对象缓存给 ViewModel，直接在 ViewModel 中用 `localStrings` 现取。

## 测试

有测试目录时，优先补充轻量测试：

- `lib/l10n/app_en.arb` 是否包含新增用户可见文案。
- ViewModel 方法是否触发预期状态。
- Page 是否只依赖 `<Feature>ViewModelType`。
- getter + `makeRebuild()` 或 `ValueStream<T>` output 是否按场景选择。
- `AppPage` 的 `routeName`、`defaultTransition` 是否正确。
- 关键页面是否能 `pumpWidget`。
