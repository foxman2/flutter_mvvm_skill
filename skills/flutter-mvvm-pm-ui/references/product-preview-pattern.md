# Product Preview 模式

PM 新增页面只放在 `lib/product_preview/`，用于演示 UI 和交互草图，不直接成为正式业务页面。

## 目录

```text
lib/product_preview/
├── pages/
│   └── sample_product_preview_page.dart
├── product_preview_entry_button.dart
├── product_preview_page.dart
└── product_preview_registry.dart
```

## 新增预览页面

在 `lib/product_preview/pages/<name>_preview_page.dart` 新增纯 UI Widget：

```dart
class CheckoutPreviewPage extends StatelessWidget {
  const CheckoutPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Preview')),
      body: const SafeArea(child: SizedBox.shrink()),
    );
  }
}
```

页面可以使用本文件内的假数据或 mock API 返回的数据，但不要创建 ViewModel、正式 AppPage case 或 route parser 分支。

## 注册预览入口

在 `product_preview_registry.dart` 添加条目：

```dart
ProductPreviewItem(
  title: 'Checkout',
  description: 'Payment and address layout preview',
  builder: (_) => const CheckoutPreviewPage(),
)
```

允许 PM 修改 registry 的 import、标题、描述和 builder。不要在 registry 中写业务判断、权限判断或 API 调用。

## 审核迁移

开发审核通过后，用 `$flutter-mvvm-feature-dev` 把预览页面迁移到正式 `lib/pages/<feature>/`，补 ViewModel、正式 AppPage、真实导航和测试。不要直接移动 PM 原型作为最终实现。
