import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../navigation/app_navigator.dart';
import 'product_preview_registry.dart';

class ProductPreviewPage extends StatelessWidget {
  const ProductPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.productPreviewTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: productPreviewItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = productPreviewItems[index];
          return Card(
            child: ListTile(
              title: Text(item.title(strings)),
              subtitle: item.description == null
                  ? null
                  : Text(item.description!(strings)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPreview(context, item),
            ),
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, ProductPreviewItem item) {
    AppNavigator.shared.show(context, item.appPage);
  }
}
