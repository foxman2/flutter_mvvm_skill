import 'package:flutter/material.dart';

class BottomSheetConfig {
  const BottomSheetConfig({
    this.enableDrag = true,
    this.barrierColor,
    this.height,
    this.topMargin,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(28)),
    this.ignoreKeyboard = false,
  });

  final bool enableDrag;
  final Color? barrierColor;
  final double? height;
  final double? topMargin;
  final BorderRadiusGeometry? borderRadius;
  final bool ignoreKeyboard;

  static const defaultConfig = BottomSheetConfig(height: 320);
}

abstract class BottomSheetConfigProvider {
  BottomSheetConfig get bottomSheetConfig;
}

class CommonBottomSheetContainer extends StatelessWidget {
  const CommonBottomSheetContainer({
    super.key,
    required this.ignoreKeyboard,
    required this.child,
    this.height,
  });

  final double? height;
  final bool ignoreKeyboard;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (height == null) {
      return child;
    }
    return SizedBox(
      height:
          height! +
          (ignoreKeyboard ? 0 : MediaQuery.of(context).viewInsets.bottom),
      child: child,
    );
  }
}
