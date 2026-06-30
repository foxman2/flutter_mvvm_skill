import 'package:flutter/material.dart';

import '../../mvvm/base_view.dart';
import 'input_alert_view_model.dart';

class InputAlertPage extends AppBaseStatefulPage<InputAlertViewModel> {
  const InputAlertPage({super.key, required super.viewModelProvider});

  @override
  State<StatefulWidget> createState() => _InputAlertPageState();
}

class _InputAlertPageState
    extends AppBaseStatefulPageState<InputAlertViewModel, InputAlertPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: viewModel.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget createWidget2(BuildContext context) {
    return AlertDialog(
      title: Text(viewModel.title ?? ''),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.content != null) ...[
            Text(viewModel.content!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: viewModel.hint,
              errorText: viewModel.errorMessage,
            ),
            onChanged: viewModel.onInputChange,
            onSubmitted: (_) {
              if (viewModel.isDoneEnabled.value) {
                viewModel.onOkClick();
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: viewModel.onCancelClick,
          child: Text(viewModel.cancelText),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: viewModel.isDoneEnabled,
          builder: (context, enabled, child) {
            return FilledButton(
              onPressed: enabled ? viewModel.onOkClick : null,
              child: child,
            );
          },
          child: Text(viewModel.okText),
        ),
      ],
    );
  }
}
