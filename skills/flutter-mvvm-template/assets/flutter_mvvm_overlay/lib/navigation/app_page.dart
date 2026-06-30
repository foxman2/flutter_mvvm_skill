import 'package:flutter/material.dart';

import '../pages/action_sheet/action_sheet_page.dart';
import '../pages/action_sheet/action_sheet_view_model.dart';
import '../pages/alert/alert_page.dart';
import '../pages/alert/alert_view_model.dart';
import '../pages/home/home_page.dart';
import '../pages/input_alert/input_alert_page.dart';
import '../pages/input_alert/input_alert_view_model.dart';
import '../widgets/common_bottom_sheet_container.dart';
import 'app_page_transition.dart';

sealed class AppPage {
  const AppPage();

  String get routeName;

  AppPageTransition get defaultTransition;

  Map<String, String> get queryParameters => {};

  WidgetBuilder generateWidgetBuilder();

  String get routeNameWithQuery {
    if (queryParameters.isEmpty) {
      return routeName;
    }
    return Uri(path: routeName, queryParameters: queryParameters).toString();
  }
}

final class HomeAppPage extends AppPage {
  const HomeAppPage();

  @override
  String get routeName => Navigator.defaultRouteName;

  @override
  AppPageTransition get defaultTransition => AppPageTransition.replaceRoot;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => const HomePage();
  }
}

final class AlertAppPage extends AppPage {
  const AlertAppPage(this.viewModel);

  final AlertViewModel viewModel;

  @override
  String get routeName => '/alert';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.alert;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => AlertPage(viewModelProvider: () => viewModel);
  }
}

final class InputAlertAppPage extends AppPage {
  const InputAlertAppPage(this.viewModel);

  final InputAlertViewModel viewModel;

  @override
  String get routeName => '/input-alert';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.alert;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => InputAlertPage(viewModelProvider: () => viewModel);
  }
}

final class ActionSheetAppPage extends AppPage {
  const ActionSheetAppPage(this.viewModel);

  final ActionSheetViewModel viewModel;

  @override
  String get routeName => '/action-sheet';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.actionSheet;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => ActionSheetPage(viewModelProvider: () => viewModel);
  }
}

final class BottomSheetDemoAppPage extends AppPage
    implements BottomSheetConfigProvider {
  const BottomSheetDemoAppPage();

  @override
  String get routeName => '/bottom-sheet-demo';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.bottomSheet;

  @override
  BottomSheetConfig get bottomSheetConfig =>
      const BottomSheetConfig(height: 280);

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => const BottomSheetDemoPage();
  }
}
