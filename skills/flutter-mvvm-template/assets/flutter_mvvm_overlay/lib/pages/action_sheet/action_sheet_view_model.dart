import 'package:flutter/foundation.dart';

import '../../mvvm/base_view_model.dart';

class ActionSheetAction {
  ActionSheetAction(this.title, {this.isDestructive = false, this.handler});

  final String title;
  final bool isDestructive;
  final VoidCallback? handler;
}

abstract class ActionSheetViewModelInput {
  void onClickAction(ActionSheetAction action);

  void onClickCancel();
}

abstract class ActionSheetViewModelOutput {
  String? get title;

  String? get message;

  List<ActionSheetAction> get actions;

  ActionSheetAction? get cancelAction;
}

abstract class ActionSheetViewModelType extends BaseViewModel
    implements ActionSheetViewModelInput, ActionSheetViewModelOutput {}

class ActionSheetViewModel extends ActionSheetViewModelType {
  ActionSheetViewModel({String? title, String? message})
    : _title = title,
      _message = message;

  final String? _title;
  final String? _message;
  final _actions = <ActionSheetAction>[];
  ActionSheetAction? _cancelAction;

  @override
  void onClickAction(ActionSheetAction action) {
    action.handler?.call();
    popUseRoot(action.title);
  }

  @override
  void onClickCancel() {
    _cancelAction?.handler?.call();
    popUseRoot();
  }

  void addAction(
    String title, {
    bool isDestructive = false,
    VoidCallback? handler,
  }) {
    _actions.add(
      ActionSheetAction(title, isDestructive: isDestructive, handler: handler),
    );
  }

  void setCancelAction([VoidCallback? handler]) {
    _cancelAction = ActionSheetAction('Cancel', handler: handler);
  }

  @override
  String? get title => _title;

  @override
  String? get message => _message;

  @override
  List<ActionSheetAction> get actions => List.unmodifiable(_actions);

  @override
  ActionSheetAction? get cancelAction => _cancelAction;
}
