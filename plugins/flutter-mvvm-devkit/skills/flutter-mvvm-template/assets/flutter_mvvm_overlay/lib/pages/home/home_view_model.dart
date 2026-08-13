import '../../mvvm/base_view_model.dart';
import '../../navigation/app_page.dart';
import '../action_sheet/action_sheet_view_model.dart';
import '../alert/alert_view_model.dart';
import '../input_alert/input_alert_view_model.dart';

/// 首页接受的用户动作。
abstract class HomeViewModelInput {
  void onClickProductPreview();

  void onClickAlertDemo();

  void onClickInputAlertDemo();

  void onClickActionSheetDemo();

  void onClickBottomSheetDemo();
}

/// 首页对外输出契约；示例当前没有额外状态。
abstract class HomeViewModelOutput {}

/// 首页 ViewModel 的完整页面契约。
abstract class HomeViewModelType extends AppBaseViewModel
    implements HomeViewModelInput, HomeViewModelOutput {}

/// 组装模板内置示例页面与弹层的导航参数。
class HomeViewModel extends HomeViewModelType {
  @override
  void onClickProductPreview() {
    show(const ProductPreviewAppPage());
  }

  @override
  void onClickAlertDemo() {
    final alert = AlertViewModel(
      title: .localized((strings) => strings.homeAlertTitle),
      content: .localized((strings) => strings.homeAlertContent),
    )..addAction(.localized((strings) => strings.commonOk), isDefault: true);
    show(AlertAppPage(alert));
  }

  @override
  void onClickInputAlertDemo() {
    final input = InputAlertViewModel(
      title: .localized((strings) => strings.homeInputAlertTitle),
      hint: .localized((strings) => strings.homeInputAlertHint),
      cancelText: .localized((strings) => strings.commonCancel),
      okText: .localized((strings) => strings.commonOk),
      onSubmitted: (value) async {
        showSuccessMessage(
          message: .localized((strings) => strings.homeSubmittedMessage(value)),
        );
      },
    );
    show(InputAlertAppPage(input));
  }

  @override
  void onClickActionSheetDemo() {
    final sheet =
        ActionSheetViewModel(
            title: .localized((strings) => strings.homeActionSheetTitle),
            message: .localized((strings) => strings.homeActionSheetMessage),
          )
          ..addAction(.localized((strings) => strings.homeNormalAction))
          ..addAction(
            .localized((strings) => strings.homeDestructiveAction),
            isDestructive: true,
          )
          ..setCancelAction(
            null,
            .localized((strings) => strings.commonCancel),
          );
    show(ActionSheetAppPage(sheet));
  }

  @override
  void onClickBottomSheetDemo() {
    show(const BottomSheetDemoAppPage());
  }
}
