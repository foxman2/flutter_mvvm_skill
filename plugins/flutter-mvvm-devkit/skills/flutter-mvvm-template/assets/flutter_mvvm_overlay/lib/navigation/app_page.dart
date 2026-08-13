import 'package:flutter/material.dart';

import '../pages/action_sheet/action_sheet_page.dart';
import '../pages/action_sheet/action_sheet_view_model.dart';
import '../pages/alert/alert_page.dart';
import '../pages/alert/alert_view_model.dart';
import '../pages/home/home_page.dart';
import '../pages/home/home_view_model.dart';
import '../pages/input_alert/input_alert_page.dart';
import '../pages/input_alert/input_alert_view_model.dart';
import '../product_preview/pages/sample_product/sample_product_page.dart';
import '../product_preview/pages/sample_product/sample_product_view_model.dart';
import '../product_preview/product_preview_page.dart';
import '../widgets/common_bottom_sheet_container.dart';
import 'app_page_transition.dart';

/// 描述业务页面的强类型路由、参数、默认转场和 Widget 工厂。
sealed class AppPage {
  const AppPage();

  String get routeName;

  AppPageTransition get defaultTransition;

  Map<String, String> get queryParameters => {};

  WidgetBuilder generateWidgetBuilder();

  /// 返回包含查询参数的完整路由名。
  String get routeNameWithQuery {
    if (queryParameters.isEmpty) {
      return routeName;
    }
    return Uri(path: routeName, queryParameters: queryParameters).toString();
  }
}

/// 应用首页路由。
final class HomeAppPage extends AppPage {
  const HomeAppPage();

  @override
  String get routeName => Navigator.defaultRouteName;

  @override
  AppPageTransition get defaultTransition => AppPageTransition.push;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => HomePage(viewModelProvider: () => HomeViewModel());
  }
}

/// Product Preview 列表页路由。
final class ProductPreviewAppPage extends AppPage {
  const ProductPreviewAppPage();

  @override
  String get routeName => '/product-preview';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.push;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => const ProductPreviewPage();
  }
}

/// Product Preview 示例页面路由。
final class SampleProductAppPage extends AppPage {
  const SampleProductAppPage();

  @override
  String get routeName => '/product-preview/sample-ui';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.push;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) =>
        SampleProductPage(viewModelProvider: () => SampleProductViewModel());
  }
}

/// 通用提示弹窗路由，复用调用方配置的 ViewModel 实例。
final class AlertAppPage extends AppPage {
  const AlertAppPage(this.viewModel);

  final AlertViewModelType viewModel;

  @override
  String get routeName => '/alert';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.alert;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => AlertPage(viewModelProvider: () => viewModel);
  }
}

/// 带输入框的提示弹窗路由。
final class InputAlertAppPage extends AppPage {
  const InputAlertAppPage(this.viewModel);

  final InputAlertViewModelType viewModel;

  @override
  String get routeName => '/input-alert';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.alert;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => InputAlertPage(viewModelProvider: () => viewModel);
  }
}

/// Cupertino Action Sheet 路由。
final class ActionSheetAppPage extends AppPage {
  const ActionSheetAppPage(this.viewModel);

  final ActionSheetViewModelType viewModel;

  @override
  String get routeName => '/action-sheet';

  @override
  AppPageTransition get defaultTransition => AppPageTransition.actionSheet;

  @override
  WidgetBuilder generateWidgetBuilder() {
    return (_) => ActionSheetPage(viewModelProvider: () => viewModel);
  }
}

/// 底部弹层示例路由及其尺寸配置。
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
