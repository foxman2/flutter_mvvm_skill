import '../l10n/display_text.dart';
import '../navigation/app_page.dart';

/// Product Preview 列表中的一个可导航示例。
class ProductPreviewItem {
  const ProductPreviewItem({
    required this.id,
    required this.title,
    required this.appPage,
    this.description,
  });

  final String id;
  final DisplayText title;
  final DisplayText? description;
  final AppPage appPage;
}

/// 应用内可浏览的 Product Preview 注册表。
final List<ProductPreviewItem> productPreviewItems = [
  ProductPreviewItem(
    id: 'sample-ui',
    title: .localized((strings) => strings.productPreviewSampleTitle),
    description: .localized(
      (strings) => strings.productPreviewSampleDescription,
    ),
    appPage: const SampleProductAppPage(),
  ),
];
