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
  String get templateTitle => 'Flutter MVVM Template';

  @override
  String get templateDescription {
    return 'Use sealed AppPage classes as page cases with typed parameters.';
  }

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
    final alert = AlertViewModel(
      title: 'Hello from MVVM',
      content:
          'This alert is opened from a view model through a sealed AppPage.',
    )..addOkAction();
    show(AlertAppPage(alert));
  }

  void _showInputAlertDemo() {
    final input = InputAlertViewModel(
      title: 'Project name',
      hint: 'my_app',
      onSubmitted: (value) async {
        showSuccessMessage(message: 'Submitted: $value');
      },
    );
    show(InputAlertAppPage(input));
  }

  void _showActionSheetDemo() {
    final sheet =
        ActionSheetViewModel(
            title: 'Choose an action',
            message: 'Action sheets are just another AppPage case.',
          )
          ..addAction('Normal action')
          ..addAction('Destructive action', isDestructive: true)
          ..setCancelAction();
    show(ActionSheetAppPage(sheet));
  }

  void _showBottomSheetDemo() {
    show(const BottomSheetDemoAppPage());
  }
}
