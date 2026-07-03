import '../l10n/app_localizations.dart';
import '../navigation/app_page.dart';
import '../navigation/app_page_transition.dart';
import 'dispose_bag.dart';
import 'error_tracker.dart';
import 'loading_tracker.dart';

abstract class BaseViewModel {
  final disposeBag = DisposeBag();

  Future<Object?> Function(AppPage page, [AppPageTransition? transition])?
  showPage;
  Future<Object?> Function(AppPage page)? pushReplacementPage;
  Future<Object?> Function(AppPage page, String untilRouteName)?
  pushAndRemoveUntilPage;
  void Function([Object? result])? popPage;
  void Function(String routeName)? popUntilPage;
  void Function()? popToRootPage;
  void Function([Object? result])? popPageUseRoot;
  void Function()? rebuild;
  AppLocalizations Function()? getLocalStrings;

  Map<String, String> get queryParameters => {};

  AppLocalizations get localStrings {
    final callback = getLocalStrings;
    if (callback == null) {
      throw StateError(
        'AppLocalizations is only available after the view model is bound to a page.',
      );
    }
    return callback();
  }

  void initState() {}

  void dispose() {
    disposeBag.dispose();
  }

  Future<Object?> show(AppPage page, [AppPageTransition? transition]) {
    return showPage?.call(page, transition) ?? Future.value(null);
  }

  Future<Object?> pushReplacement(AppPage page) {
    return pushReplacementPage?.call(page) ?? Future.value(null);
  }

  Future<Object?> pushAndRemoveUntil(AppPage page, String untilRouteName) {
    return pushAndRemoveUntilPage?.call(page, untilRouteName) ??
        Future.value(null);
  }

  void pop([Object? result]) {
    popPage?.call(result);
  }

  void popUntil(String routeName) {
    popUntilPage?.call(routeName);
  }

  void popToRoot() {
    popToRootPage?.call();
  }

  void popUseRoot([Object? result]) {
    popPageUseRoot?.call(result);
  }

  void makeRebuild() {
    rebuild?.call();
  }
}

abstract class AppBaseViewModel extends BaseViewModel {
  final loadingTracker = LoadingTracker();
  final errorTracker = ErrorTracker();

  void Function(String? message)? showSuccessMessageImpl;
  void Function(String? message)? showFailMessageImpl;
  void Function(String? message)? showNormalMessageImpl;

  bool get hookBackButton => true;

  Future<bool> onWillPop() async => true;

  void showSuccessMessage({String? message}) {
    showSuccessMessageImpl?.call(message);
  }

  void showFailMessage({String? message}) {
    showFailMessageImpl?.call(message);
  }

  void showNormalMessage({String? message}) {
    showNormalMessageImpl?.call(message);
  }

  @override
  void dispose() {
    loadingTracker.dispose();
    errorTracker.dispose();
    super.dispose();
  }
}

extension LoadingAndErrorTrack<T> on Future<T> {
  Future<T?> trackLoadingAndConsumeError(AppBaseViewModel viewModel) {
    return trackLoading(
      viewModel.loadingTracker,
    ).consumeError(viewModel.errorTracker);
  }
}
