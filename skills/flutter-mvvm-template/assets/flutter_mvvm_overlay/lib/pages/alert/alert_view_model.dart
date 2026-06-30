import 'package:flutter/material.dart';

import '../../mvvm/base_view_model.dart';

class AlertViewAction {
  AlertViewAction(
    this.title, {
    this.isDefault = false,
    this.isDestructive = false,
    this.handler,
  });

  final String title;
  final bool isDefault;
  final bool isDestructive;
  final VoidCallback? handler;
}

class AlertViewModel extends BaseViewModel {
  AlertViewModel({this.title, this.content, this.richTitle, this.richContent});

  String? title;
  String? content;
  TextSpan? richTitle;
  TextSpan? richContent;
  bool cancelable = true;
  VoidCallback? cancelHandler;
  final actions = <AlertViewAction>[];

  void onPop(Object? result) {
    if (result == null) {
      cancelHandler?.call();
    }
  }

  void addAction(
    String title, {
    bool isDefault = false,
    bool isDestructive = false,
    VoidCallback? handler,
  }) {
    actions.add(
      AlertViewAction(
        title,
        isDefault: isDefault,
        isDestructive: isDestructive,
        handler: handler,
      ),
    );
  }

  void addCancelAction([VoidCallback? handler]) {
    addAction('Cancel', handler: handler);
  }

  void addOkAction([VoidCallback? handler]) {
    addAction('OK', isDefault: true, handler: handler);
  }

  void addDeleteAction([VoidCallback? handler]) {
    addAction('Delete', isDestructive: true, handler: handler);
  }
}
