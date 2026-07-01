# UI 修改模式

## 修改前

先看当前页面和相邻页面：

- 是否使用 `Scaffold`、`AppBar`、`ListView`、`CustomScrollView`、`SafeArea`。
- 按钮使用 `FilledButton`、`OutlinedButton`、`TextButton` 还是项目自定义组件。
- 间距、圆角、颜色、字体是否来自 `Theme.of(context)`。
- 页面动作是否已经通过 ViewModel 方法暴露。

## 职责边界

Widget 中保留：

- 布局结构
- 文案展示
- 绑定 `onPressed: viewModel.someAction`
- 根据 ViewModel 状态显示不同 UI

ViewModel 中保留：

- 点击后的业务动作
- 异步加载
- loading/error 展示
- 页面跳转
- 弹窗、ActionSheet、BottomSheet 调用

避免在 Widget 里直接写复杂流程：

```dart
onPressed: () async {
  await api.save();
  Navigator.of(context).push(...);
}
```

优先写成：

```dart
onPressed: viewModel.saveAndOpenDetail
```

## 弹窗

普通错误优先走 `errorTracker`，由基类统一展示。

业务确认弹窗可以创建独立 ViewModel 和 `AlertAppPage`，由当前 ViewModel 发起：

```dart
void confirmDelete() {
  final alert = AlertViewModel(
    title: '确认删除',
    content: '删除后不可恢复。',
  )
    ..addCancelAction()
    ..addDestructiveAction(title: '删除', handler: delete);
  show(AlertAppPage(alert));
}
```

如果项目已有固定 alert ViewModel API，按现有 API 写。

## ActionSheet

多个互斥操作优先使用 `ActionSheetAppPage` 或项目已有 action sheet：

```dart
void showMoreActions() {
  final sheet = ActionSheetViewModel(title: '更多操作')
    ..addAction(title: '编辑', handler: edit)
    ..addAction(title: '分享', handler: share)
    ..addCancelAction();
  show(ActionSheetAppPage(sheet));
}
```

## BottomSheet

内容较复杂、需要完整布局或内部导航时，创建独立页面和对应 `AppPage`：

- 简单静态内容：`bottomSheet`
- 弹层内部还要 push 子页面：`bottomSheetWithNavigator`
- 高度、拖拽、顶部间距走 `BottomSheetConfigProvider`

## 视觉一致性

- 优先复用已有 widget 和 theme，不临时发明一套样式。
- 不把业务页面改成孤立的“展示 demo”风格。
- 移动端页面要检查长文案、按钮文本和小屏滚动。
- 表单类 UI 要处理键盘、安全区和错误提示。
