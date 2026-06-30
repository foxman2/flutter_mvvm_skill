import 'package:flutter/material.dart';

import '../../mvvm/base_view.dart';
import 'home_view_model.dart';

class HomePage extends AppBaseStatelessPage<HomeViewModel> {
  const HomePage({super.key}) : super(viewModelProvider: _defaultProvider);

  static HomeViewModel? _defaultProvider() => null;

  @override
  HomeViewModel? defaultViewModel() => HomeViewModel();

  @override
  Widget createWidget(BuildContext context, HomeViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mvvm Skill Test')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Flutter MVVM Template',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Use sealed AppPage classes as page cases with typed parameters.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: viewModel.showAlertDemo,
            child: const Text('Show alert'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: viewModel.showInputAlertDemo,
            child: const Text('Show input alert'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: viewModel.showActionSheetDemo,
            child: const Text('Show action sheet'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: viewModel.showBottomSheetDemo,
            child: const Text('Show bottom sheet'),
          ),
        ],
      ),
    );
  }
}

class BottomSheetDemoPage extends StatelessWidget {
  const BottomSheetDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bottom sheet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('This page is presented by BottomSheetDemoAppPage.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
