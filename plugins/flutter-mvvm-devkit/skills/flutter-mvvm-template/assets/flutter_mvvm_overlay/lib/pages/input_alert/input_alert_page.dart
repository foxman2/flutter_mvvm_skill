import 'package:flutter/material.dart';

import '../../mvvm/base_view.dart';
import '../../widgets/value_stream_builder.dart';
import 'input_alert_view_model.dart';

class InputAlertPage extends AppBaseStatefulPage<InputAlertViewModelType> {
  const InputAlertPage({super.key, required super.viewModelProvider});

  @override
  State<StatefulWidget> createState() => _InputAlertPageState();
}

class _InputAlertPageState
    extends AppBaseStatefulPageState<InputAlertViewModelType, InputAlertPage> {
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
    final title = viewModel.title?.resolve(context);
    final content = viewModel.content?.resolve(context);
    final hint = viewModel.hint?.resolve(context);
    final errorMessage = viewModel.errorMessage?.resolve(context);
    final cancelText = viewModel.cancelText.resolve(context);
    final okText = viewModel.okText.resolve(context);
    return AlertDialog(
      title: Text(title ?? ''),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content != null) ...[Text(content), const SizedBox(height: 12)],
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorMessage,
            ),
            onChanged: viewModel.onInputText,
            onSubmitted: (_) {
              if (viewModel.isDoneEnabled.value) {
                viewModel.onClickOk();
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: viewModel.onClickCancel, child: Text(cancelText)),
        ValueStreamBuilder<bool>(
          stream: viewModel.isDoneEnabled,
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            return FilledButton(
              onPressed: enabled ? viewModel.onClickOk : null,
              child: Text(okText),
            );
          },
        ),
      ],
    );
  }
}
