# 页面和 ViewModel 模式

## 开始前先观察

新增页面前，先读 1-2 个相似页面：

- `lib/pages/<feature>/<feature>_page.dart`
- `lib/pages/<feature>/<feature>_view_model.dart`
- 页面对应的 `AppPage` case
- 相关 widget 或测试
- `lib/l10n/app_en.arb` 中已有的文案命名方式

优先沿用已有页面的组织方式。ViewModel 页面统一使用
`AppBaseStatefulPage<T>` 和对应 state；即使页面没有本地 controller、animation、
focus 或 tab，也通过 state 持有并绑定 ViewModel。

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
- 页面跳转用 `show(...)`、`pushReplacement(...)`、`pushAndRemoveUntil(...)`、`replaceRoot(...)`。
- 关闭页面用 `pop(...)`、`popUseRoot(...)` 或项目已有封装。

## Page 写法

`ViewModelProvider<T>` 是返回非空 ViewModel 的工厂，但 provider 本身可以为
`null`。每个 ViewModel Page 都要显式接收 `required super.viewModelProvider`，
让调用点明确选择默认实现或注入工厂。

ViewModel 需要参数时，Page 不提供默认实现，也不接收已创建的 ViewModel 实例：

```dart
import '../../l10n/app_localizations.dart';

class ProfilePage extends AppBaseStatefulPage<ProfileViewModelType> {
  const ProfilePage({
    super.key,
    required this.userId,
    required super.viewModelProvider,
  });

  final String userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState
    extends AppBaseStatefulPageState<ProfileViewModelType, ProfilePage> {
  @override
  Widget createWidget2(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(viewModel.title)),
      body: Center(child: Text(strings.profileDescription)),
    );
  }
}
```

对应 `AppPage` 在 WidgetBuilder 内放入 provider 工厂，ViewModel 会在 Page 的
`initState()` 才创建：

```dart
@override
WidgetBuilder generateWidgetBuilder() {
  return (_) => ProfilePage(
    userId: userId,
    viewModelProvider: () => ProfileViewModel(userId: userId),
  );
}
```

只有 ViewModel 无构造参数且无外部依赖时才覆盖 `defaultViewModel()`：

```dart
class HomePage extends AppBaseStatefulPage<HomeViewModelType> {
  const HomePage({super.key, required super.viewModelProvider});

  @override
  HomeViewModelType defaultViewModel() => HomeViewModel();

  @override
  State<HomePage> createState() => _HomePageState();
}
```

调用方必须写出 `HomePage(viewModelProvider: null)`。不要用返回 `null` 的
`_defaultProvider()` 占位，也不要让非空 provider 返回 nullable ViewModel。

Alert、ActionSheet、child ViewModel 等特殊场景可能需要先配置动作、回调或父子关系。
修改前先确认谁创建、谁绑定、谁释放；不要仅为了统一写法改变现有所有权。

页面或纯 Widget 中只负责展示的文案直接用 `AppLocalizations.of(context)!`。需要由 ViewModel 发起的弹窗、toast、ActionSheet 和状态文案不要从 Widget 传字符串对象缓存给 ViewModel，直接在 ViewModel 中用 `localStrings` 现取。

## 测试决策

先运行覆盖受影响行为的已有测试。只有以下变化需要新增针对性测试：

- ViewModel 包含非平凡状态转换、异步竞争或错误恢复。
- 页面包含稳定且关键的用户交互，或本次改动修复了回归问题。
- 自定义导航参数或 transition 包含无法由类型系统覆盖的分支。

纯布局、文案、样式、l10n key 是否存在、class/provider 类型结构、普通 route metadata 和简单 getter/setter 默认不新增测试；这些优先由代码审查、编译器和 `flutter analyze` 覆盖。不要把 `test/` 目录存在当作补测试条件。
