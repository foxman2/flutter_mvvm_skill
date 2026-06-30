import 'package:flutter/cupertino.dart';

import '../../mvvm/base_view.dart';
import 'action_sheet_view_model.dart';

class ActionSheetPage extends BaseStatefulView<ActionSheetViewModel> {
  const ActionSheetPage({super.key, required super.viewModelProvider});

  @override
  State<ActionSheetPage> createState() => _ActionSheetPageState();
}

class _ActionSheetPageState
    extends BaseStatefulViewState<ActionSheetViewModel, ActionSheetPage> {
  @override
  Widget createWidget(BuildContext context) {
    return CupertinoActionSheet(
      title: viewModel.title == null ? null : Text(viewModel.title!),
      message: viewModel.message == null ? null : Text(viewModel.message!),
      actions: [
        for (final action in viewModel.actions)
          CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            onPressed: () {
              action.handler?.call();
              Navigator.of(context, rootNavigator: true).pop(action.title);
            },
            child: Text(action.title),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          viewModel.cancelAction?.handler?.call();
          Navigator.of(context, rootNavigator: true).pop();
        },
        child: Text(viewModel.cancelAction?.title ?? 'Cancel'),
      ),
    );
  }
}
