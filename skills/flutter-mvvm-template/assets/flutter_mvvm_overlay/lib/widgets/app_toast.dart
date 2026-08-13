import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastType { success, fail, normal }

class AppToastController {
  AppToastController();

  static final shared = AppToastController();

  static const animationDuration = Duration(milliseconds: 200);
  static const messageDuration = Duration(seconds: 2);
  static const normalMessageDuration = Duration(seconds: 1);

  OverlayEntry? _entry;
  GlobalKey<_AppToastOverlayState>? _toastKey;
  Timer? _displayTimer;
  Timer? _removalTimer;

  void show(
    BuildContext context, {
    required AppToastType type,
    required String message,
    Duration? duration,
  }) {
    _removeCurrent();

    final overlay = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey<_AppToastOverlayState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppToastOverlay(key: key, type: type, message: message),
    );
    _entry = entry;
    _toastKey = key;
    overlay.insert(entry);

    final displayDuration =
        duration ??
        (type == AppToastType.normal ? normalMessageDuration : messageDuration);
    _displayTimer = Timer(displayDuration, () => _hide(entry, key));
  }

  void dismiss() {
    final entry = _entry;
    final key = _toastKey;
    if (entry == null || key == null) {
      return;
    }
    _hide(entry, key);
  }

  void _hide(OverlayEntry entry, GlobalKey<_AppToastOverlayState> key) {
    if (!identical(_entry, entry)) {
      return;
    }

    _displayTimer?.cancel();
    _displayTimer = null;
    final state = key.currentState;
    if (state == null) {
      _remove(entry);
      return;
    }

    state.hide();
    _removalTimer?.cancel();
    _removalTimer = Timer(animationDuration, () => _remove(entry));
  }

  void _removeCurrent() {
    _displayTimer?.cancel();
    _removalTimer?.cancel();
    _displayTimer = null;
    _removalTimer = null;
    final entry = _entry;
    _entry = null;
    _toastKey = null;
    entry?.remove();
  }

  void _remove(OverlayEntry entry) {
    if (!identical(_entry, entry)) {
      return;
    }
    _removeCurrent();
  }
}

class _AppToastOverlay extends StatefulWidget {
  const _AppToastOverlay({
    super.key,
    required this.type,
    required this.message,
  });

  final AppToastType type;
  final String message;

  @override
  State<_AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<_AppToastOverlay> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  void hide() {
    if (mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (widget.type) {
      AppToastType.success => Icons.done,
      AppToastType.fail => Icons.clear,
      AppToastType.normal => null,
    };
    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Center(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: AppToastController.animationDuration,
              child: Semantics(
                liveRegion: true,
                label: widget.message,
                child: Container(
                  margin: const EdgeInsets.all(50),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null)
                        Icon(icon, color: Colors.white, size: 40),
                      if (icon != null && widget.message.isNotEmpty)
                        const SizedBox(height: 10),
                      if (widget.message.isNotEmpty)
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
