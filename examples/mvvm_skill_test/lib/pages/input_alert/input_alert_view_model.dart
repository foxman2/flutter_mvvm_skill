import 'package:flutter/material.dart';

import '../../mvvm/base_view_model.dart';

class InputAlertViewModel extends AppBaseViewModel {
  InputAlertViewModel({
    this.title,
    this.content,
    this.hint,
    this.initialValue = '',
    this.allowEmpty = false,
    this.onSubmitted,
  });

  String? title;
  String? content;
  String? hint;
  String initialValue;
  bool allowEmpty;
  String cancelText = 'Cancel';
  String okText = 'OK';
  String inputContent = '';
  String? errorMessage;
  Future<void> Function(String value)? onSubmitted;

  final isDoneEnabled = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    inputContent = initialValue;
    isDoneEnabled.value = allowEmpty || inputContent.trim().isNotEmpty;
  }

  void onInputChange(String value) {
    inputContent = value.trim();
    isDoneEnabled.value = allowEmpty || inputContent.isNotEmpty;
  }

  Future<void> onOkClick() async {
    await onSubmitted?.call(inputContent);
    pop(inputContent);
  }

  void onCancelClick() {
    pop();
  }

  @override
  void dispose() {
    isDoneEnabled.dispose();
    super.dispose();
  }
}
