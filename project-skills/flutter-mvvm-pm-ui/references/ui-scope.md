# PM UI 改动范围

## 可以改

- 页面展示结构、文案、颜色、字体、间距、图标、空态、loading/empty/error 的呈现。
- `lib/pages/**/<feature>_page.dart` 中已有 ViewModel output 的展示方式。
- `onPressed: viewModel.onClickXxx` 这类已有 input 绑定的按钮位置和样式。
- 纯展示组件：`lib/widgets/`、`lib/theme/`、页面局部 `widgets/`。
- 产品预览入口按钮：`lib/product_preview/product_preview_entry_button.dart`。
- 隔离页面的同目录 ViewModel：`lib/product_preview/pages/<feature>/<feature>_view_model.dart`。
- 配合 `$flutter-mvvm-mock-api-dev` 时，可以按其规则修改临时 `lib/services/api/<domain>_api_service.dart`、`lib/services/api/api_service.dart` 的实例 wiring、`lib/services/mock_api/` 和 mock-only model；全部标记为 `PM preview / pending developer review`。全局入口保持 `AppContainer.shared`。

## 不可以改

- 正式 `lib/pages/**/<feature>_view_model.dart` 中的状态、异步流程、业务动作、弹窗和导航决策。
- `lib/navigation/`，除了模板已提供的 `ProductPreviewAppPage` 不再追加 PM 页面 case。
- 已确认的正式 API/model、真实 Dio 请求，以及 `AppContainer` 持有的正式业务依赖及其逻辑。
- Widget 里新增业务流程，例如直接调用 API、解析 JSON、写缓存、判断登录态、决定下一步业务路由。

## 绑定规则

Widget 可以绑定已有 ViewModel input 方法：

```dart
FilledButton(
  onPressed: viewModel.onClickSubmit,
  child: const Text('Submit'),
)
```

隔离页面可以绑定同目录 ViewModel input 方法，但这些方法只表达展示状态和临时交互，不接正式业务流程。

input 方法命名保持简短：点击用 `onClickXxx`，输入用 `onInputXxx`，不要默认追加 `Button`、`Field`、`Tile` 等控件类型后缀。

展示状态优先读取 output getter；只有输入联动、进度、倒计时、刷新状态和一次性 UI 事件等局部高频状态才用 `ValueStream<T>`/`Stream<T>`。

Widget 不要把业务流程写进回调：

```dart
onPressed: () async {
  await AppContainer.shared.apiService.order.submit();
  Navigator.of(context).push(...);
}
```

如果正式 UI 需要新动作，先在 PM 输出中描述需求，由开发用 `$flutter-mvvm-feature-dev` 增加正式 ViewModel 行为。
