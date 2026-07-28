import '../l10n/app_localizations.dart';
import '../navigation/app_page.dart';

class ProductPreviewItem {
  const ProductPreviewItem({
    required this.id,
    required this.title,
    required this.appPage,
    this.description,
  });

  final String id;
  final String Function(AppLocalizations strings) title;
  final String Function(AppLocalizations strings)? description;
  final AppPage appPage;
}

final List<ProductPreviewItem> productPreviewItems = [
  ProductPreviewItem(
    id: 'sample-ui',
    title: (strings) => strings.productPreviewSampleTitle,
    description: (strings) => strings.productPreviewSampleDescription,
    appPage: const SampleProductAppPage(),
  ),
];
