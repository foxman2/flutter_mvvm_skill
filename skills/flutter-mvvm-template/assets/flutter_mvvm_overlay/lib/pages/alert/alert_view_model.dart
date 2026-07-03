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

abstract class AlertViewModelInput {
  void onPop(Object? result);

  void onClickAction(AlertViewAction action);
}

abstract class AlertViewModelOutput {
  String? get title;

  String? get content;

  TextSpan? get richTitle;

  TextSpan? get richContent;

  bool get cancelable;

  List<AlertViewAction> get actions;
}

abstract class AlertViewModelType extends BaseViewModel
    implements AlertViewModelInput, AlertViewModelOutput {}

class AlertViewModel extends AlertViewModelType {
  AlertViewModel({
    String? title,
    String? content,
    TextSpan? richTitle,
    TextSpan? richContent,
    bool cancelable = true,
    VoidCallback? cancelHandler,
  }) : _title = title,
       _content = content,
       _richTitle = richTitle,
       _richContent = richContent,
       _cancelable = cancelable,
       _cancelHandler = cancelHandler;

  final String? _title;
  final String? _content;
  final TextSpan? _richTitle;
  final TextSpan? _richContent;
  final bool _cancelable;
  final VoidCallback? _cancelHandler;
  final _actions = <AlertViewAction>[];

  @override
  void onPop(Object? result) {
    if (result == null) {
      _cancelHandler?.call();
    }
  }

  @override
  void onClickAction(AlertViewAction action) {
    action.handler?.call();
    popUseRoot(action.title);
  }

  void addAction(
    String title, {
    bool isDefault = false,
    bool isDestructive = false,
    VoidCallback? handler,
  }) {
    _actions.add(
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

  @override
  String? get title => _title;

  @override
  String? get content => _content;

  @override
  TextSpan? get richTitle => _richTitle;

  @override
  TextSpan? get richContent => _richContent;

  @override
  bool get cancelable => _cancelable;

  @override
  List<AlertViewAction> get actions => List.unmodifiable(_actions);
}
