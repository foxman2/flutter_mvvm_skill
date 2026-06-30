import 'package:flutter/foundation.dart';

import '../../mvvm/base_view_model.dart';

class ActionSheetAction {
  ActionSheetAction(this.title, {this.isDestructive = false, this.handler});

  final String title;
  final bool isDestructive;
  final VoidCallback? handler;
}

class ActionSheetViewModel extends BaseViewModel {
  ActionSheetViewModel({this.title, this.message});

  String? title;
  String? message;
  final actions = <ActionSheetAction>[];
  ActionSheetAction? cancelAction;

  void addAction(
    String title, {
    bool isDestructive = false,
    VoidCallback? handler,
  }) {
    actions.add(
      ActionSheetAction(title, isDestructive: isDestructive, handler: handler),
    );
  }

  void setCancelAction([VoidCallback? handler]) {
    cancelAction = ActionSheetAction('Cancel', handler: handler);
  }
}
