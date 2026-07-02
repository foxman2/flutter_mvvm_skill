import 'package:flutter/material.dart';

import 'product_preview_registry.dart';

class ProductPreviewPage extends StatelessWidget {
  const ProductPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Preview')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: productPreviewItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = productPreviewItems[index];
          return Card(
            child: ListTile(
              title: Text(item.title),
              subtitle: item.description == null
                  ? null
                  : Text(item.description!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPreview(context, item),
            ),
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, ProductPreviewItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: item.builder,
        settings: RouteSettings(name: '/product-preview/${item.id}'),
      ),
    );
  }
}
