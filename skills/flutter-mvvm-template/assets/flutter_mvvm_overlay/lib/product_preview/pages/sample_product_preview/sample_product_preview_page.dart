import 'package:flutter/material.dart';

import '../../../mvvm/base_view.dart';
import 'sample_product_preview_view_model.dart';

class SampleProductPreviewPage
    extends AppBaseStatelessPage<SampleProductPreviewViewModel> {
  const SampleProductPreviewPage({super.key})
    : super(viewModelProvider: _defaultProvider);

  static SampleProductPreviewViewModel? _defaultProvider() => null;

  @override
  SampleProductPreviewViewModel? defaultViewModel() {
    return SampleProductPreviewViewModel();
  }

  @override
  Widget createWidget(
    BuildContext context,
    SampleProductPreviewViewModel viewModel,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sample UI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Product Preview Area', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create isolated preview pages here, then ask development '
              'to review and migrate approved UI into formal MVVM pages.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mock content', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(viewModel.mockContentDescription),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
