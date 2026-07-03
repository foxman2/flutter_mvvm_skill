import '../../mvvm/base_view_model.dart';
import '../../navigation/app_page.dart';
import '../action_sheet/action_sheet_view_model.dart';
import '../alert/alert_view_model.dart';
import '../input_alert/input_alert_view_model.dart';

abstract class HomeViewModelInput {
  void onClickProductPreview();

  void onClickAlertDemo();

  void onClickInputAlertDemo();

  void onClickActionSheetDemo();

  void onClickBottomSheetDemo();
}

abstract class HomeViewModelOutput {
  String get templateTitle;

  String get templateDescription;
}

abstract class HomeViewModelType extends AppBaseViewModel
    implements HomeViewModelInput, HomeViewModelOutput {}

class HomeViewModel extends HomeViewModelType {
  @override
  String get templateTitle => localStrings.homeTemplateTitle;

  @override
  String get templateDescription => localStrings.homeTemplateDescription;

  @override
  void onClickProductPreview() {
    _showProductPreview();
  }

  @override
  void onClickAlertDemo() {
    _showAlertDemo();
  }

  @override
  void onClickInputAlertDemo() {
    _showInputAlertDemo();
  }

  @override
  void onClickActionSheetDemo() {
    _showActionSheetDemo();
  }

  @override
  void onClickBottomSheetDemo() {
    _showBottomSheetDemo();
  }

  void _showProductPreview() {
    show(const ProductPreviewAppPage());
  }

  void _showAlertDemo() {
    final strings = localStrings;
    final alert = AlertViewModel(
      title: strings.homeAlertTitle,
      content: strings.homeAlertContent,
    )..addAction(strings.commonOk, isDefault: true);
    show(AlertAppPage(alert));
  }

  void _showInputAlertDemo() {
    final strings = localStrings;
    final input = InputAlertViewModel(
      title: strings.homeInputAlertTitle,
      hint: strings.homeInputAlertHint,
      cancelText: strings.commonCancel,
      okText: strings.commonOk,
      onSubmitted: (value) async {
        showSuccessMessage(message: localStrings.homeSubmittedMessage(value));
      },
    );
    show(InputAlertAppPage(input));
  }

  void _showActionSheetDemo() {
    final strings = localStrings;
    final sheet =
        ActionSheetViewModel(
            title: strings.homeActionSheetTitle,
            message: strings.homeActionSheetMessage,
          )
          ..addAction(strings.homeNormalAction)
          ..addAction(strings.homeDestructiveAction, isDestructive: true)
          ..setCancelAction(null, strings.commonCancel);
    show(ActionSheetAppPage(sheet));
  }

  void _showBottomSheetDemo() {
    show(const BottomSheetDemoAppPage());
  }
}
