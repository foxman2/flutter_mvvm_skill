import 'package:flutter/widgets.dart';

import 'pages/sample_product_preview_page.dart';

class ProductPreviewItem {
  const ProductPreviewItem({
    required this.id,
    required this.title,
    required this.builder,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final WidgetBuilder builder;
}

final List<ProductPreviewItem> productPreviewItems = [
  ProductPreviewItem(
    id: 'sample-ui',
    title: 'Sample UI',
    description: 'A safe place for PM-owned UI previews before dev review.',
    builder: (_) => const SampleProductPreviewPage(),
  ),
];
