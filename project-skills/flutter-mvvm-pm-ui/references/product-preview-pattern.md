# Product Preview 模式

PM 新增页面只放在 `lib/product_preview/`，用于演示 UI 和交互草图，不直接成为正式业务页面。页面内部按正式 `$flutter-mvvm-feature-dev` 的 page/ViewModel/组件拆分规则实现；隔离点只放在目录边界，不放在文件名或类名里。

## 目录

```text
lib/
├── navigation/
│   └── app_page.dart
└── product_preview/
    ├── pages/
    │   └── checkout/
    │       ├── checkout_page.dart
    │       └── checkout_view_model.dart
    ├── product_preview_entry_button.dart
    ├── product_preview_page.dart
    └── product_preview_registry.dart
```

## 新增页面

在 `lib/product_preview/pages/<feature>/` 下新增 page 和 ViewModel。命名规则和正式页面完全一致：

- 文件：`<feature>_page.dart`、`<feature>_view_model.dart`
- 类型：`<Feature>Page`、`<Feature>ViewModelInput`、`<Feature>ViewModelOutput`、`<Feature>ViewModelType`、`<Feature>ViewModel`
- 不要在 `<Feature>` 和 `Page` / `ViewModel` 之间追加 `Preview`，也不要在 `<feature>` 和 `_page.dart` / `_view_model.dart` 之间追加 `_preview`

先在 `lib/l10n/app_en.arb` 添加预览所需文案：

```json
{
  "productPreviewCheckoutTitle": "Checkout",
  "productPreviewCheckoutDescription": "Payment and address layout preview",
  "productPreviewCheckoutAddress": "Address",
  "productPreviewCheckoutPayment": "Payment",
  "productPreviewCheckoutSummary": "Summary"
}
```

```dart
abstract class CheckoutViewModelInput {
  void onClickDemoItem(String item);
}

abstract class CheckoutViewModelOutput {
  List<String> get demoItems;
}

abstract class CheckoutViewModelType extends AppBaseViewModel
    implements CheckoutViewModelInput, CheckoutViewModelOutput {}

class CheckoutViewModel extends CheckoutViewModelType {
  @override
  void onClickDemoItem(String item) {
    makeRebuild();
  }

  @override
  List<String> get demoItems => [
    localStrings.productPreviewCheckoutAddress,
    localStrings.productPreviewCheckoutPayment,
    localStrings.productPreviewCheckoutSummary,
  ];
}
```

```dart
class CheckoutPage extends AppBaseStatefulPage<CheckoutViewModelType> {
  const CheckoutPage({super.key, required super.viewModelProvider});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState
    extends AppBaseStatefulPageState<CheckoutViewModelType, CheckoutPage> {
  @override
  Widget createWidget2(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.productPreviewCheckoutTitle)),
      body: const SafeArea(child: SizedBox.shrink()),
    );
  }
}
```

页面使用同目录 ViewModel 管理展示状态和临时交互。需要列表、卡片、详情、状态等业务形态数据时，用 `$flutter-mvvm-mock-api-dev` 的目录和审核规则新增或复用 mock service。ViewModel 通过构造函数接收具体 domain service，AppPage provider 从 `AppContainer.shared` 取得并传入。本文件或 ViewModel 中的本地常量只用于纯布局占位、tab/选中态、筛选项等没有 service 层价值的小型 UI 状态。ViewModel 遵守正式 input/output/type 结构；默认 output 使用 getter + `makeRebuild()`，只有频繁或局部刷新才用 `ValueStream<T>`。

## AppPage 与预览注册

在 `app_page.dart` 添加普通 AppPage。没有外部依赖时直接构造 ViewModel：

```dart
final class CheckoutAppPage extends AppPage {
  const CheckoutAppPage();

  @override
  String get routeName => '/product-preview/checkout';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.push;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => CheckoutPage(
      viewModelProvider: () => CheckoutViewModel(),
    );
  }
}
```

需要 mock domain service 时，先让 ViewModel 构造函数接收对应 contract，再在同一个
provider 中注入：

```dart
viewModelProvider: () => CheckoutViewModel(
  orderApiService: AppContainer.shared.apiService.order,
),
```

在 `product_preview_registry.dart` 添加条目：

```dart
ProductPreviewItem(
  id: 'checkout',
  title: (strings) => strings.productPreviewCheckoutTitle,
  description: (strings) => strings.productPreviewCheckoutDescription,
  appPage: const CheckoutAppPage(),
)
```

`ProductPreviewItem` 保存 AppPage，列表通过 `AppNavigator` 打开它。允许 PM 修改
registry 的 import、标题、描述和 appPage。registry 不负责创建 ViewModel，也不写
业务判断、权限判断或 API 调用。预览 AppPage 与其他 AppPage 使用相同导航能力。

## 审核迁移

开发审核通过后，用 `$flutter-mvvm-feature-dev` 把页面迁移到正式
`lib/pages/<feature>/`，把对应 AppPage 调整为正式业务页面定义，按行为风险决定是否
需要针对性测试，并把临时展示状态替换成正式业务状态。不要直接把临时 mock 或 demo
逻辑当成最终实现。
