import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'pages/sample_product_preview/sample_product_preview_page.dart';

class ProductPreviewItem {
  const ProductPreviewItem({
    required this.id,
    required this.title,
    required this.builder,
    this.description,
  });

  final String id;
  final String Function(AppLocalizations strings) title;
  final String Function(AppLocalizations strings)? description;
  final WidgetBuilder builder;
}

final List<ProductPreviewItem> productPreviewItems = [
  ProductPreviewItem(
    id: 'sample-ui',
    title: (strings) => strings.productPreviewSampleTitle,
    description: (strings) => strings.productPreviewSampleDescription,
    builder: (_) => const SampleProductPreviewPage(),
  ),
];
