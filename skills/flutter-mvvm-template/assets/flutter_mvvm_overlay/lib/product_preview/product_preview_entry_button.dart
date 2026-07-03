import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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
