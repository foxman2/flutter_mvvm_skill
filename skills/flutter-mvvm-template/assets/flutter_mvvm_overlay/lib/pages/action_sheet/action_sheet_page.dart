import 'package:flutter/cupertino.dart';

import '../../mvvm/base_view.dart';
import 'action_sheet_view_model.dart';

class ActionSheetPage extends BaseStatefulView<ActionSheetViewModelType> {
  const ActionSheetPage({super.key, required super.viewModelProvider});

  @override
  State<ActionSheetPage> createState() => _ActionSheetPageState();
}

class _ActionSheetPageState
    extends BaseStatefulViewState<ActionSheetViewModelType, ActionSheetPage> {
  @override
  Widget createWidget(BuildContext context) {
    final title = viewModel.title?.resolve(context);
    final message = viewModel.message?.resolve(context);
    final cancelTitle =
        (viewModel.cancelAction?.title ??
                .localized((strings) => strings.commonCancel))
            .resolve(context);
    return CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: [
        for (final action in viewModel.actions) _buildAction(context, action),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: viewModel.onClickCancel,
        child: Text(cancelTitle),
      ),
    );
  }

  Widget _buildAction(BuildContext context, ActionSheetAction action) {
    final title = action.title.resolve(context);
    return CupertinoActionSheetAction(
      isDestructiveAction: action.isDestructive,
      onPressed: () => viewModel.onClickAction(action, title),
      child: Text(title),
    );
  }
}
