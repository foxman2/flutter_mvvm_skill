import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 打开 Product Preview 的统一悬浮入口按钮。
class ProductPreviewEntryButton extends StatelessWidget {
  const ProductPreviewEntryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      heroTag: 'product-preview-entry-button',
      onPressed: onPressed,
      icon: const Icon(Icons.visibility_outlined),
      label: Text(strings.productPreviewTitle),
    );
  }
}
