import 'package:flutter/material.dart';

import '../../mvvm/base_view.dart';
import 'alert_view_model.dart';

class AlertPage extends BaseStatefulView<AlertViewModel> {
  const AlertPage({super.key, required super.viewModelProvider});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends BaseStatefulViewState<AlertViewModel, AlertPage> {
  @override
  Widget createWidget(BuildContext context) {
    final actions = viewModel.actions.isEmpty
        ? [AlertViewAction('OK', isDefault: true)]
        : viewModel.actions;

    return PopScope<Object?>(
      canPop: viewModel.cancelable,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          viewModel.onPop(result);
        }
      },
      child: AlertDialog(
        title: viewModel.richTitle == null
            ? Text(viewModel.title ?? '')
            : Text.rich(viewModel.richTitle!),
        content: viewModel.richContent == null
            ? (viewModel.content == null ? null : Text(viewModel.content!))
            : Text.rich(viewModel.richContent!),
        actions: [
          for (final action in actions)
            TextButton(
              onPressed: () {
                action.handler?.call();
                Navigator.of(context, rootNavigator: true).pop(action.title);
              },
              child: Text(
                action.title,
                style: TextStyle(
                  fontWeight: action.isDefault
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: action.isDestructive ? Colors.red : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
