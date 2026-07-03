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
    return CupertinoActionSheet(
      title: viewModel.title == null ? null : Text(viewModel.title!),
      message: viewModel.message == null ? null : Text(viewModel.message!),
      actions: [
        for (final action in viewModel.actions)
          CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            onPressed: () => viewModel.onClickAction(action),
            child: Text(action.title),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: viewModel.onClickCancel,
        child: Text(viewModel.cancelAction?.title ?? 'Cancel'),
      ),
    );
  }
}
