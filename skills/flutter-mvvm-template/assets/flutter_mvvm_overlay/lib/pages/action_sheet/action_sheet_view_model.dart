import 'package:flutter/foundation.dart';

import '../../l10n/display_text.dart';
import '../../mvvm/base_view_model.dart';

/// Action Sheet 中的单个操作。
class ActionSheetAction {
  ActionSheetAction(this.title, {this.isDestructive = false, this.handler});

  final DisplayText title;
  final bool isDestructive;
  final VoidCallback? handler;
}

/// Action Sheet 接受的用户动作。
abstract class ActionSheetViewModelInput {
  void onClickAction(ActionSheetAction action, String resolvedTitle);

  void onClickCancel();
}

/// Action Sheet 渲染所需的只读状态。
abstract class ActionSheetViewModelOutput {
  DisplayText? get title;

  DisplayText? get message;

  List<ActionSheetAction> get actions;

  ActionSheetAction? get cancelAction;
}

/// Action Sheet ViewModel 的完整页面契约。
abstract class ActionSheetViewModelType extends BaseViewModel
    implements ActionSheetViewModelInput, ActionSheetViewModelOutput {}

/// 管理 Action Sheet 的普通操作和取消操作。
class ActionSheetViewModel extends ActionSheetViewModelType {
  ActionSheetViewModel({this.title, this.message});

  @override
  final DisplayText? title;

  @override
  final DisplayText? message;

  final _actions = <ActionSheetAction>[];
  ActionSheetAction? _cancelAction;

  @override
  void onClickAction(ActionSheetAction action, String resolvedTitle) {
    action.handler?.call();
    popUseRoot(resolvedTitle);
  }

  @override
  void onClickCancel() {
    _cancelAction?.handler?.call();
    popUseRoot();
  }

  /// 按展示顺序添加一个普通操作。
  void addAction(
    DisplayText title, {
    bool isDestructive = false,
    VoidCallback? handler,
  }) {
    _actions.add(
      ActionSheetAction(title, isDestructive: isDestructive, handler: handler),
    );
  }

  /// 配置独立显示的取消操作。
  void setCancelAction([VoidCallback? handler, DisplayText? title]) {
    _cancelAction = ActionSheetAction(
      title ?? .localized((strings) => strings.commonCancel),
      handler: handler,
    );
  }

  @override
  List<ActionSheetAction> get actions => List.unmodifiable(_actions);

  @override
  ActionSheetAction? get cancelAction => _cancelAction;
}
