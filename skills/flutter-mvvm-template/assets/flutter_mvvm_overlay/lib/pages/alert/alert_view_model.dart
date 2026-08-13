import 'package:flutter/material.dart';

import '../../l10n/display_text.dart';
import '../../mvvm/base_view_model.dart';

/// 提示弹窗中的单个操作及其视觉语义。
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

/// 提示弹窗接受的用户动作。
abstract class AlertViewModelInput {
  void onPop(Object? result);

  void onClickAction(AlertViewAction action, String resolvedTitle);
}

/// 提示弹窗渲染所需的只读状态。
abstract class AlertViewModelOutput {
  DisplayText? get title;

  DisplayText? get content;

  DisplayTextSpan? get richTitle;

  DisplayTextSpan? get richContent;

  bool get cancelable;

  List<AlertViewAction> get actions;
}

/// 提示弹窗 ViewModel 的完整页面契约。
abstract class AlertViewModelType extends BaseViewModel
    implements AlertViewModelInput, AlertViewModelOutput {}

/// 管理提示内容、操作列表和取消回调。
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

  /// 按展示顺序添加一个操作。
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
