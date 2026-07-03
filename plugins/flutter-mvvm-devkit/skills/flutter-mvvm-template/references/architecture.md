# Flutter MVVM Template 架构边界

## 模板边界

- 模板代码要独立于产品专属服务：Firebase、推送处理、运行时语言切换、资源、认证/session manager 和领域 manager 都留在应用层。
- 网络层只预设基础 `ApiService` 规则：Dio setup、通用请求、错误转换、代码级 API 环境切换和 `user` real/mock 示例模块，不预设真实业务接口或后端响应协议。
- 跨项目可复用的生命周期代码放到 `mvvm/`：view model 绑定、dispose 管理、loading/error 跟踪和基础 page widget。
- 模板默认启用 Flutter 官方 l10n，当前只提供 `en`。用户可见文案放在 `lib/l10n/app_en.arb`；Page/Widget 直接用 `AppLocalizations.of(context)!`，ViewModel 通过 `BaseViewModel.localStrings` callback 现用现取。
- `localStrings` 只能在页面绑定后使用；不要在 ViewModel 构造函数或 `initState()` 里读取本地化文案。
- 页面级 ViewModel 必须按 input/output/type 拆分：Page 泛型只依赖 `<Feature>ViewModelType`，实现类只在 `defaultViewModel()` 或注入点中出现。
- input 方法只描述用户事件：点击用简短 `onClickXxx`，输入用 `onInputXxx`；业务目的放在实现类私有方法里。
- output 默认用 getter + `makeRebuild()`。只有输入联动、进度、倒计时、刷新状态和一次性 UI 事件等高频或局部刷新场景使用 `ValueStream<T>`/`Stream<T>` 与 `ValueStreamBuilder<T>`。
- 导航基础能力放到 `navigation/`：page model、navigator、route parser、transition enum 和 observer。
- 通用 UI 保持小而可替换：alert、input alert、action sheet、bottom sheet 是示例，不是完整设计系统。
- 优先使用回调或 view model 方法，不要从通用模板里直接导入业务模块。
- 这个模板只负责生成新项目，不包含已有项目改造步骤。

## 生成项目结构

```text
lib/
├── app.dart
├── l10n/
├── main.dart
├── models/
├── mvvm/
├── navigation/
├── pages/
├── product_preview/
│   └── pages/
├── services/
│   ├── api/
│   └── mock_api/
│       └── models/
└── widgets/
```

页面 ViewModel 推荐结构：

```dart
abstract class ProfileViewModelInput {
  void onClickClose();
}

abstract class ProfileViewModelOutput {}
abstract class ProfileViewModelType extends AppBaseViewModel
    implements ProfileViewModelInput, ProfileViewModelOutput {}

class ProfileViewModel extends ProfileViewModelType {}
```

`main.dart` 负责初始化 `AppServices` 并启动应用。`app.dart` 负责 `MaterialApp`、navigator observers、主题和 EasyLoading builder。

`product_preview/` 是 UI 预览隔离区。首页通过悬浮按钮进入 `ProductPreviewAppPage`，新增预览页面放在 `product_preview/pages/` 并通过 `product_preview_registry.dart` 注册；审核通过后再迁移到正式 `pages/`、ViewModel 和 AppPage 导航。

## 生成后检查清单

1. 运行 `flutter pub get`。
2. 运行 `dart format lib test`。
3. 运行 `flutter analyze`。
4. 运行 `flutter test`。
5. 打开生成项目，确认 `lib/mvvm/`、`lib/navigation/`、`lib/pages/`、`lib/services/`、`lib/models/` 和 `test/` 都已覆盖到位。

## 不要放入模板的内容

- 业务页面和领域 view model。
- 真实业务 API、认证/session manager 和领域 manager。
- 后台未确认的 mock-only model；新增时先放在 `lib/services/mock_api/models/`，确认后再合并到正式 model。
- 未经开发审核的隔离预览页面；这类页面先留在 `lib/product_preview/`。
- Retrofit、Chopper、freezed、json_serializable 或其他代码生成依赖。
- Firebase、推送通知、app link 和 analytics 配置。
- 产品资源、运行时语言切换、应用专属主题。
- 平台目录，除非用户明确想复制完整项目。
