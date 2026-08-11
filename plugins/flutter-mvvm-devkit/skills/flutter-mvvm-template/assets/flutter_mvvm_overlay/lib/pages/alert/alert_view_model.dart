import 'package:flutter/material.dart';

import '../../l10n/display_text.dart';
import '../../mvvm/base_view_model.dart';

class AlertViewAction {
  AlertViewAction(
    this.title, {
    this.isDefault = false,
    this.isDestructive = false,
    this.handler,
  });

  final DisplayText title;
  final bool isDefault;
  final bool isDestructive;
  final VoidCallback? handler;
}

abstract class AlertViewModelInput {
  void onPop(Object? result);

  void onClickAction(AlertViewAction action, String resolvedTitle);
}

abstract class AlertViewModelOutput {
  DisplayText? get title;

  DisplayText? get content;

  DisplayTextSpan? get richTitle;

  DisplayTextSpan? get richContent;

  bool get cancelable;

  List<AlertViewAction> get actions;
}

abstract class AlertViewModelType extends BaseViewModel
    implements AlertViewModelInput, AlertViewModelOutput {}

class AlertViewModel extends AlertViewModelType {
  factory AlertViewModel({
    DisplayText? title,
    DisplayText? content,
    DisplayTextSpan? richTitle,
    DisplayTextSpan? richContent,
    bool cancelable = true,
    VoidCallback? cancelHandler,
  }) {
    return AlertViewModel._(
      title: title,
      content: content,
      richTitle: richTitle,
      richContent: richContent,
      cancelable: cancelable,
      cancelHandler: cancelHandler,
    );
  }

  AlertViewModel._({
    required this._title,
    required this._content,
    required this._richTitle,
    required this._richContent,
    required this._cancelable,
    required this._cancelHandler,
  });

  final DisplayText? _title;
  final DisplayText? _content;
  final DisplayTextSpan? _richTitle;
  final DisplayTextSpan? _richContent;
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
  void onClickAction(AlertViewAction action, String resolvedTitle) {
    action.handler?.call();
    popUseRoot(resolvedTitle);
  }

  void addAction(
    DisplayText title, {
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

  @override
  DisplayText? get title => _title;

  @override
  DisplayText? get content => _content;

  @override
  DisplayTextSpan? get richTitle => _richTitle;

  @override
  DisplayTextSpan? get richContent => _richContent;

  @override
  bool get cancelable => _cancelable;

  @override
  List<AlertViewAction> get actions => List.unmodifiable(_actions);
}
