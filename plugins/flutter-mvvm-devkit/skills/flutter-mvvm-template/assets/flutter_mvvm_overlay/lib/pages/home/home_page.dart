import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../mvvm/base_view.dart';
import '../../product_preview/product_preview_entry_button.dart';
import 'home_view_model.dart';

class HomePage extends AppBaseStatefulPage<HomeViewModelType> {
  const HomePage({super.key}) : super(viewModelProvider: _defaultProvider);

  static HomeViewModelType? _defaultProvider() => null;

  @override
  HomeViewModelType? defaultViewModel() => HomeViewModel();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState
    extends AppBaseStatefulPageState<HomeViewModelType, HomePage> {
  @override
  Widget createWidget2(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.appTitle)),
      floatingActionButton: ProductPreviewEntryButton(
        onPressed: viewModel.onClickProductPreview,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            viewModel.templateTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.templateDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: viewModel.onClickAlertDemo,
            child: Text(strings.homeShowAlert),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: viewModel.onClickInputAlertDemo,
            child: Text(strings.homeShowInputAlert),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: viewModel.onClickActionSheetDemo,
            child: Text(strings.homeShowActionSheet),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: viewModel.onClickBottomSheetDemo,
            child: Text(strings.homeShowBottomSheet),
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
    final strings = AppLocalizations.of(context)!;
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
                strings.bottomSheetDemoTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(strings.bottomSheetDemoDescription),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.bottomSheetDemoDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
