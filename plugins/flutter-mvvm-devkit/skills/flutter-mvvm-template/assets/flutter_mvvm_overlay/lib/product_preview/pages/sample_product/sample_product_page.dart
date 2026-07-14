import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../mvvm/base_view.dart';
import 'sample_product_view_model.dart';

class SampleProductPage
    extends AppBaseStatefulPage<SampleProductViewModelType> {
  const SampleProductPage({super.key})
    : super(viewModelProvider: _defaultProvider);

  static SampleProductViewModelType? _defaultProvider() => null;

  @override
  SampleProductViewModelType? defaultViewModel() {
    return SampleProductViewModel();
  }

  @override
  State<SampleProductPage> createState() => _SampleProductPageState();
}

class _SampleProductPageState
    extends
        AppBaseStatefulPageState<
          SampleProductViewModelType,
          SampleProductPage
        > {
  @override
  Widget createWidget2(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(strings.productPreviewSampleTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              strings.productPreviewAreaTitle,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.productPreviewAreaDescription,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.productPreviewMockContentTitle,
                      style: textTheme.titleMedium,
                    ),
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
