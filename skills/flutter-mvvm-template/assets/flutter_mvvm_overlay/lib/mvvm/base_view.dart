import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../l10n/app_localizations.dart';
import '../navigation/app_navigator.dart';
import '../navigation/app_page.dart';
import '../navigation/app_page_transition.dart';
import '../pages/alert/alert_view_model.dart';
import 'base_view_model.dart';
import 'dispose_bag.dart';
import 'error_tracker.dart';

typedef ViewModelProvider<T extends BaseViewModel> = T Function();

abstract class BaseStatefulView<ViewModel extends BaseViewModel>
    extends StatefulWidget {
  const BaseStatefulView({super.key, required this.viewModelProvider});

  final ViewModelProvider<ViewModel>? viewModelProvider;

  ViewModel defaultViewModel() {
    throw StateError('Provide a view model or override defaultViewModel().');
  }

  ViewModel createViewModel() =>
      viewModelProvider?.call() ?? defaultViewModel();
}

abstract class BaseStatefulViewState<
  ViewModel extends BaseViewModel,
  T extends BaseStatefulView<ViewModel>
>
    extends State<T> {
  final disposeBag = DisposeBag();
  late ViewModel viewModel;

  @mustCallSuper
  void bindViewModel() {
    viewModel.showPage = _show;
    disposeBag.add(() => viewModel.showPage = null);

    viewModel.pushReplacementPage = _pushReplacement;
    disposeBag.add(() => viewModel.pushReplacementPage = null);

    viewModel.replaceRootPage = _replaceRoot;
    disposeBag.add(() => viewModel.replaceRootPage = null);

    viewModel.pushAndRemoveUntilPage = _pushAndRemoveUntil;
    disposeBag.add(() => viewModel.pushAndRemoveUntilPage = null);

    viewModel.popPage = _pop;
    disposeBag.add(() => viewModel.popPage = null);

    viewModel.popUntilPage = _popUntil;
    disposeBag.add(() => viewModel.popUntilPage = null);

    viewModel.popToRootPage = _popToRoot;
    disposeBag.add(() => viewModel.popToRootPage = null);

    viewModel.popPageUseRoot = _popUseRoot;
    disposeBag.add(() => viewModel.popPageUseRoot = null);

    viewModel.getLocalStrings = () => AppLocalizations.of(context)!;
    disposeBag.add(() => viewModel.getLocalStrings = null);

    viewModel.rebuild = () {
      if (mounted) {
        setState(() {});
      }
    };
    disposeBag.add(() => viewModel.rebuild = null);
  }

  Future<Object?> _show(AppPage page, [AppPageTransition? transition]) {
    return AppNavigator.shared.show(context, page, transition);
  }

  Future<Object?> _pushReplacement(AppPage page) {
    return AppNavigator.shared.pushReplacement(context, page);
  }

  Future<Object?> _replaceRoot(AppPage page) {
    return AppNavigator.shared.replaceRoot(context, page);
  }

  Future<Object?> _pushAndRemoveUntil(AppPage page, String untilRouteName) {
    return AppNavigator.shared.pushAndRemoveUntil(
      context,
      page,
      untilRouteName,
    );
  }

  void _pop([Object? result]) {
    AppNavigator.shared.safePop(context, result);
  }

  void _popUntil(String routeName) {
    AppNavigator.shared.popUntil(context, routeName);
  }

  void _popToRoot() {
    AppNavigator.shared.popToRoot(context);
  }

  void _popUseRoot([Object? result]) {
    AppNavigator.shared.popUseRoot(context, result);
  }

  @override
  void initState() {
    super.initState();
    viewModel = widget.createViewModel();
    viewModel.initState();
    bindViewModel();
  }

  @override
  void dispose() {
    disposeBag.dispose();
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return createWidget(context);
  }

  Widget createWidget(BuildContext context);
}

typedef AppBaseStatefulPage<ViewModel extends AppBaseViewModel> =
    BaseStatefulView<ViewModel>;

abstract class AppBaseStatefulPageState<
  ViewModel extends AppBaseViewModel,
  T extends AppBaseStatefulPage<ViewModel>
>
    extends BaseStatefulViewState<ViewModel, T> {
  var _isShowingLoading = false;

  @override
  @mustCallSuper
  void bindViewModel() {
    super.bindViewModel();
    viewModel.loadingTracker.isLoading
        .listen(_updateLoadingState)
        .disposeBy(disposeBag);
    viewModel.errorTracker.stream.listen(_handleError).disposeBy(disposeBag);

    viewModel.showSuccessMessageImpl = _showSuccessMessage;
    disposeBag.add(() => viewModel.showSuccessMessageImpl = null);

    viewModel.showFailMessageImpl = _showFailMessage;
    disposeBag.add(() => viewModel.showFailMessageImpl = null);

    viewModel.showNormalMessageImpl = _showNormalMessage;
    disposeBag.add(() => viewModel.showNormalMessageImpl = null);
  }

  @override
  void dispose() {
    _updateLoadingState(false);
    super.dispose();
  }

  Future<bool> onWillPop() {
    if (_isShowingLoading) {
      _updateLoadingState(false);
      return Future.value(false);
    }
    return viewModel.onWillPop();
  }

  void _updateLoadingState(bool isLoading) {
    if (isLoading && !_isShowingLoading) {
      EasyLoading.show(maskType: EasyLoadingMaskType.clear);
      _isShowingLoading = true;
    } else if (!isLoading && _isShowingLoading) {
      EasyLoading.dismiss();
      _isShowingLoading = false;
    }
  }

  void _handleError(AppError error) {
    final strings = viewModel.localStrings;
    final alert = AlertViewModel(
      title: error.title ?? strings.commonErrorTitle,
      content: error.message,
    )..addAction(strings.commonOk, isDefault: true);
    _show(AlertAppPage(alert));
  }

  void _showSuccessMessage(String? message) {
    EasyLoading.showSuccess(message ?? '');
  }

  void _showFailMessage(String? message) {
    EasyLoading.showError(message ?? '');
  }

  void _showNormalMessage(String? message) {
    EasyLoading.showToast(message ?? '', duration: const Duration(seconds: 1));
  }

  @override
  Widget createWidget(BuildContext context) {
    final child = createWidget2(context);
    if (!viewModel.hookBackButton) {
      return child;
    }
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: child,
    );
  }

  Widget createWidget2(BuildContext context);
}
