# PM UI 改动范围

## 可以改

- 页面展示结构、文案、颜色、字体、间距、图标、空态、loading/empty/error 的呈现。
- `lib/pages/**/<feature>_page.dart` 中已有 ViewModel 状态的展示方式。
- `onPressed: viewModel.someAction` 这类已有事件绑定的按钮位置和样式。
- 纯展示组件：`lib/widgets/`、`lib/theme/`、页面局部 `widgets/`。
- PM 入口按钮：`lib/product_preview/product_preview_entry_button.dart`。

## 不可以改

- `*_view_model.dart` 中的状态、异步流程、业务动作、弹窗和导航决策。
- `lib/navigation/`，除了模板已提供的 `ProductPreviewAppPage` 不再追加 PM 页面 case。
- `lib/services/api/`、正式 `lib/models/`、repository、manager、session、auth、analytics、push、storage。
- Widget 里新增业务流程，例如直接调用 API、解析 JSON、写缓存、判断登录态、决定下一步业务路由。

## 绑定规则

Widget 可以绑定已有 ViewModel 方法：

```dart
FilledButton(
  onPressed: viewModel.submit,
  child: const Text('Submit'),
)
```

Widget 不要把业务流程写进回调：

```dart
onPressed: () async {
  await ApiService.shared.order.submit();
  Navigator.of(context).push(...);
}
```

如果 UI 需要新动作，先在 PM 输出中描述需求，由开发用 `$flutter-mvvm-feature-dev` 增加 ViewModel 行为。
