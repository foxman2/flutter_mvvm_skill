import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/common_bottom_sheet_container.dart';
import 'app_page.dart';
import 'app_page_transition.dart';

/// 将强类型 [AppPage] 映射为具体 Flutter 路由和弹层 API。
class AppNavigator {
  AppNavigator._();

  static final shared = AppNavigator._();
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// 按页面默认转场或调用方指定转场展示页面。
  Future<Object?> show(
    BuildContext context,
    AppPage page, [
    AppPageTransition? transition,
  ]) {
    switch (transition ?? page.defaultTransition) {
      case AppPageTransition.push:
        return _push(context, page);
      case AppPageTransition.alert:
        return _showAlert(context, page);
      case AppPageTransition.actionSheet:
        return _showActionSheet(context, page);
      case AppPageTransition.bottomSheet:
        return _showModalBottomSheet(context, page);
      case AppPageTransition.bottomSheetWithNavigator:
        return _showModalBottomSheetWithNavigator(context, page);
      case AppPageTransition.page:
        return _pushPage(context, page);
    }
  }

  /// 为路由生成统一的名称和原始路由标识。
  static RouteSettings routeSettingsFor(
    AppPage page, {
    required bool isFullScreen,
  }) {
    return RouteSettings(
      name: isFullScreen ? page.routeNameWithQuery : null,
      arguments: page.routeName,
    );
  }

  Future<Object?> _push(BuildContext context, AppPage page) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: page.generateWidgetBuilder(),
        settings: routeSettingsFor(page, isFullScreen: true),
      ),
    );
  }

  Future<Object?> _showAlert(BuildContext context, AppPage page) {
    return showDialog<Object?>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: page.generateWidgetBuilder(),
      routeSettings: routeSettingsFor(page, isFullScreen: false),
    );
  }

  Future<Object?> _showActionSheet(BuildContext context, AppPage page) {
    return showCupertinoModalPopup<Object?>(
      context: context,
      builder: page.generateWidgetBuilder(),
      routeSettings: routeSettingsFor(page, isFullScreen: false),
    );
  }

  Future<Object?> _showModalBottomSheet(BuildContext context, AppPage page) {
    final config = page is BottomSheetConfigProvider
        ? (page as BottomSheetConfigProvider).bottomSheetConfig
        : BottomSheetConfig.defaultConfig;
    return _showModalBottomSheetWithChild(
      context,
      page.generateWidgetBuilder()(context),
      config,
      settings: routeSettingsFor(page, isFullScreen: false),
    );
  }

  Future<Object?> _showModalBottomSheetWithNavigator(
    BuildContext context,
    AppPage page,
  ) {
    final config = page is BottomSheetConfigProvider
        ? (page as BottomSheetConfigProvider).bottomSheetConfig
        : BottomSheetConfig.defaultConfig;
    return _showModalBottomSheetWithChild(
      context,
      _createNavigator(page.generateWidgetBuilder()),
      config,
      settings: routeSettingsFor(page, isFullScreen: false),
    );
  }

  Widget _createNavigator(WidgetBuilder builder) {
    final key = GlobalKey<NavigatorState>();
    final initialRoute = MaterialPageRoute(builder: builder);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final state = key.currentState;
        // 优先回退弹层内部导航栈，栈底再交给根导航器关闭弹层。
        if (state != null && state.canPop()) {
          state.maybePop();
          return;
        }
        navigatorKey.currentState?.maybePop(result);
      },
      child: Navigator(
        key: key,
        onGenerateInitialRoutes: (_, _) => [initialRoute],
      ),
    );
  }

  Future<Object?> _showModalBottomSheetWithChild(
    BuildContext context,
    Widget child,
    BottomSheetConfig config, {
    RouteSettings? settings,
  }) {
    final shape = config.borderRadius == null
        ? null
        : RoundedRectangleBorder(borderRadius: config.borderRadius!);
    final clipBehavior = config.borderRadius == null ? null : Clip.antiAlias;
    return showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      shape: shape,
      clipBehavior: clipBehavior,
      enableDrag: config.enableDrag,
      isDismissible: config.enableDrag,
      routeSettings: settings,
      barrierColor: config.barrierColor,
      useRootNavigator: true,
      backgroundColor: config.topMargin == null ? null : Colors.transparent,
      builder: (_) {
        double? height = config.height;
        if (height == null && config.topMargin != null) {
          final mediaQuery = MediaQuery.of(context);
          height =
              mediaQuery.size.height -
              mediaQuery.padding.top -
              config.topMargin!;
        }
        return CommonBottomSheetContainer(
          height: height,
          ignoreKeyboard: config.ignoreKeyboard,
          child: child,
        );
      },
    );
  }

  Future<Object?> _pushPage(BuildContext context, AppPage page) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page.generateWidgetBuilder()(context),
        settings: routeSettingsFor(page, isFullScreen: true),
      ),
    );
  }

  /// 用新页面替换当前路由。
  Future<Object?> pushReplacement(BuildContext context, AppPage page) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: page.generateWidgetBuilder(),
        settings: routeSettingsFor(page, isFullScreen: true),
      ),
    );
  }

  /// 清空现有路由并将新页面设为根页面。
  Future<Object?> replaceRoot(BuildContext context, AppPage page) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: page.generateWidgetBuilder(),
        settings: routeSettingsFor(page, isFullScreen: true),
      ),
      (_) => false,
    );
  }

  /// 推入新页面并移除路由，直到命中指定路由名。
  Future<Object?> pushAndRemoveUntil(
    BuildContext context,
    AppPage page,
    String untilRouteName,
  ) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: page.generateWidgetBuilder(),
        settings: routeSettingsFor(page, isFullScreen: true),
      ),
      (route) => route.settings.arguments == untilRouteName,
    );
  }

  /// 优先回退当前导航器，无法回退时再尝试根导航器。
  void safePop(BuildContext context, [Object? result]) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result);
      return;
    }
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop(result);
    }
  }

  void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(
      context,
      (route) => route.settings.arguments == routeName,
    );
  }

  void popToRoot(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void popUseRoot(BuildContext context, [Object? result]) {
    Navigator.of(context, rootNavigator: true).pop(result);
  }
}

/// 记录当前栈顶业务路由名，供调试和导航状态读取。
class AppNavigatorObserver extends NavigatorObserver {
  String? lastRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastRouteName = route.settings.arguments as String?;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    lastRouteName = newRoute?.settings.arguments as String?;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastRouteName = previousRoute?.settings.arguments as String?;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.arguments == lastRouteName) {
      lastRouteName = previousRoute?.settings.arguments as String?;
    }
  }
}

/// 判断当前上下文是否位于 Material 底部弹层路由中。
bool isInBottomSheet(BuildContext context) {
  return ModalRoute.of(context) is ModalBottomSheetRoute;
}
