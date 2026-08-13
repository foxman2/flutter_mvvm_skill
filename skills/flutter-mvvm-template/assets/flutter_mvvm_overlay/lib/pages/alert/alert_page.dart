import 'package:flutter/material.dart';

import '../../mvvm/base_view.dart';
import 'alert_view_model.dart';

class AlertPage extends BaseStatefulView<AlertViewModelType> {
  const AlertPage({super.key, required super.viewModelProvider});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState
    extends BaseStatefulViewState<AlertViewModelType, AlertPage> {
  @override
  Widget createWidget(BuildContext context) {
    final actions = viewModel.actions.isEmpty
        ? [
            AlertViewAction(
              .localized((strings) => strings.commonOk),
              isDefault: true,
            ),
          ]
        : viewModel.actions;
    final richTitle = viewModel.richTitle?.resolve(context);
    final title = richTitle == null ? viewModel.title?.resolve(context) : null;
    final richContent = viewModel.richContent?.resolve(context);
    final content = richContent == null
        ? viewModel.content?.resolve(context)
        : null;

    return PopScope<Object?>(
      canPop: viewModel.cancelable,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          viewModel.onPop(result);
        }
      },
      child: AlertDialog(
        title: richTitle == null
            ? (title == null ? null : Text(title))
            : Text.rich(richTitle),
        content: richContent == null
            ? (content == null ? null : Text(content))
            : Text.rich(richContent),
        actions: [for (final action in actions) _buildAction(context, action)],
      ),
    );
  }

  Widget _buildAction(BuildContext context, AlertViewAction action) {
    final title = action.title.resolve(context);
    return TextButton(
      onPressed: () => viewModel.onClickAction(action, title),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: action.isDefault ? FontWeight.w700 : FontWeight.w400,
          color: action.isDestructive ? Colors.red : null,
        ),
      ),
    );
  }
}
