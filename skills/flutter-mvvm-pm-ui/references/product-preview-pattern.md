# Product Preview 模式

PM 新增页面只放在 `lib/product_preview/`，用于演示 UI 和交互草图，不直接成为正式业务页面。页面内部尽量遵循正式 `$flutter-mvvm-feature-dev` 的 page/ViewModel/组件拆分规则，隔离点只放在目录边界。

## 目录

```text
lib/product_preview/
├── pages/
│   └── checkout/
│       ├── checkout_page.dart
│       └── checkout_view_model.dart
├── product_preview_entry_button.dart
├── product_preview_page.dart
└── product_preview_registry.dart
```

## 新增预览页面

在 `lib/product_preview/pages/<feature>/` 下新增 page 和 preview-only ViewModel。命名规则和正式页面保持一致：

```dart
class CheckoutViewModel extends AppBaseViewModel {
  final List<String> demoItems = const ['Address', 'Payment', 'Summary'];

  void selectDemoItem(String item) {
    makeRebuild();
  }
}
```

```dart
class CheckoutPage extends AppBaseStatelessPage<CheckoutViewModel> {
  const CheckoutPage({super.key}) : super(viewModelProvider: _defaultProvider);

  static CheckoutViewModel? _defaultProvider() => null;

  @override
  CheckoutViewModel? defaultViewModel() => CheckoutViewModel();

  @override
  Widget createWidget(BuildContext context, CheckoutViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Preview')),
      body: const SafeArea(child: SizedBox.shrink()),
    );
  }
}
```

页面可以使用同目录 preview-only ViewModel、本文件假数据或 mock API 返回的数据。不要创建正式 AppPage case、route parser 分支、正式 ViewModel 或真实 API 接入。

## 注册预览入口

在 `product_preview_registry.dart` 添加条目：

```dart
ProductPreviewItem(
  id: 'checkout',
  title: 'Checkout',
  description: 'Payment and address layout preview',
  builder: (_) => const CheckoutPage(),
)
```

允许 PM 修改 registry 的 import、标题、描述和 builder。不要在 registry 中写业务判断、权限判断或 API 调用。

## 审核迁移

开发审核通过后，用 `$flutter-mvvm-feature-dev` 把预览页面迁移到正式 `lib/pages/<feature>/`，补正式 AppPage、真实导航和测试，并把 preview-only 状态替换成正式业务状态。不要直接把临时 mock 或 demo 逻辑当成最终实现。
