import '../../mvvm/base_view_model.dart';
import '../../navigation/app_page.dart';
import '../action_sheet/action_sheet_view_model.dart';
import '../alert/alert_view_model.dart';
import '../input_alert/input_alert_view_model.dart';

class HomeViewModel extends AppBaseViewModel {
  void showProductPreview() {
    show(const ProductPreviewAppPage());
  }

  void showAlertDemo() {
    final alert = AlertViewModel(
      title: 'Hello from MVVM',
      content:
          'This alert is opened from a view model through a sealed AppPage.',
    )..addOkAction();
    show(AlertAppPage(alert));
  }

  void showInputAlertDemo() {
    final input = InputAlertViewModel(
      title: 'Project name',
      hint: 'my_app',
      onSubmitted: (value) async {
        showSuccessMessage(message: 'Submitted: $value');
      },
    );
    show(InputAlertAppPage(input));
  }

  void showActionSheetDemo() {
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

  void showBottomSheetDemo() {
    show(const BottomSheetDemoAppPage());
  }
}
