import 'package:flutter/material.dart';

class ProductPreviewEntryButton extends StatelessWidget {
  const ProductPreviewEntryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'product-preview-entry-button',
      onPressed: onPressed,
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('PM Preview'),
    );
  }
}
