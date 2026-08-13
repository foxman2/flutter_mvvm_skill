import 'package:flutter/material.dart';

class AppLoadingDialogController {
  AppLoadingDialogController();

  static final shared = AppLoadingDialogController();

  final _activeOwners = <Object>{};
  DialogRoute<void>? _route;
  BuildContext? _latestContext;
  var _showRequestedAfterDismiss = false;

  void update({
    required Object owner,
    required bool isLoading,
    required BuildContext context,
  }) {
    if (isLoading) {
      _latestContext = context;
      _activeOwners.add(owner);
      final route = _route;
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
      navigator.removeRoute(route);
    }
  }
}
