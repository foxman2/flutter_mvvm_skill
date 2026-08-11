import 'package:flutter/foundation.dart';

import '../../l10n/display_text.dart';
import '../../mvvm/base_view_model.dart';

class ActionSheetAction {
  ActionSheetAction(this.title, {this.isDestructive = false, this.handler});

  final DisplayText title;
  final bool isDestructive;
  final VoidCallback? handler;
}

abstract class ActionSheetViewModelInput {
  void onClickAction(ActionSheetAction action, String resolvedTitle);

  void onClickCancel();
}

abstract class ActionSheetViewModelOutput {
  DisplayText? get title;

  DisplayText? get message;

  List<ActionSheetAction> get actions;

  ActionSheetAction? get cancelAction;
}

abstract class ActionSheetViewModelType extends BaseViewModel
    implements ActionSheetViewModelInput, ActionSheetViewModelOutput {}

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

  void addAction(
    DisplayText title, {
    bool isDestructive = false,
    VoidCallback? handler,
  }) {
    _actions.add(
      ActionSheetAction(title, isDestructive: isDestructive, handler: handler),
    );
  }

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
