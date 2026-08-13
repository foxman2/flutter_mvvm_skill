import 'package:flutter/material.dart';

/// 在根导航器上统一管理全局 Loading Dialog。
///
/// 控制器按 owner 聚合多个页面的加载状态，只展示一个 Dialog，并在所有
/// owner 结束后定向移除对应路由，避免误关页面或其他弹层。
class AppLoadingDialogController {
  AppLoadingDialogController();

  static final shared = AppLoadingDialogController();

  final _activeOwners = <Object>{};
  DialogRoute<void>? _route;
  BuildContext? _latestContext;
  var _showRequestedAfterDismiss = false;

  /// 更新指定 [owner] 的加载状态。
  void update({
    required Object owner,
    required bool isLoading,
    required BuildContext context,
  }) {
    if (isLoading) {
      _latestContext = context;
      _activeOwners.add(owner);
      final route = _route;
      // 路由正在响应系统返回时，只有新的 true 事件才请求在关闭后重显。
      if (route != null && !route.isCurrent) {
        _showRequestedAfterDismiss = true;
      }
      _showIfNeeded(context);
      return;
    }

    _activeOwners.remove(owner);
    if (_activeOwners.isEmpty) {
      _showRequestedAfterDismiss = false;
      _latestContext = null;
      _dismiss();
    }
  }

  /// 页面销毁时解除 owner，不影响其他仍在加载的页面。
  void detach(Object owner) {
    _activeOwners.remove(owner);
    if (_activeOwners.isEmpty) {
      _showRequestedAfterDismiss = false;
      _latestContext = null;
      _dismiss();
    }
  }

  void _showIfNeeded(BuildContext context) {
    if (_route != null || _activeOwners.isEmpty || !context.mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      barrierDismissible: false,
      useSafeArea: false,
      requestFocus: false,
      builder: (_) => Center(
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                backgroundColor: Color(0x4DFFFFFF),
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      ),
    );
    _route = route;
    navigator.push<void>(route).whenComplete(() {
      // 系统返回可能先关闭 Dialog；仅处理仍由当前控制器持有的同一路由。
      if (identical(_route, route)) {
        _route = null;
        final context = _latestContext;
        if (_showRequestedAfterDismiss && context != null && context.mounted) {
          _showRequestedAfterDismiss = false;
          _showIfNeeded(context);
        }
      }
    });
  }

  void _dismiss() {
    final route = _route;
    if (route == null) {
      return;
    }

    _route = null;
    final navigator = route.navigator;
    if (navigator != null && route.isActive) {
      // 定向移除 Loading 路由，不能使用 pop 以免误关顶部的其他弹层或页面。
      navigator.removeRoute(route);
    }
  }
}
