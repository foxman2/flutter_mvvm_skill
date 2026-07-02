import 'package:flutter/material.dart';

class SampleProductPreviewPage extends StatelessWidget {
  const SampleProductPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sample UI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('PM Preview Area', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create product-owned preview pages here, then ask development '
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
                    const Text(
                      'Use mock API services for data-driven previews, and '
                      'mark those data-layer changes as pending dev review.',
                    ),
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
