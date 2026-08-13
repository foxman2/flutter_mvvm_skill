import 'package:flutter/material.dart';

/// 定义通用底部弹层的尺寸、外观和交互行为。
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

/// 允许 [AppPage] 为底部弹层提供专属配置。
abstract class BottomSheetConfigProvider {
  BottomSheetConfig get bottomSheetConfig;
}

/// 根据固定高度和键盘策略约束底部弹层内容。
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
