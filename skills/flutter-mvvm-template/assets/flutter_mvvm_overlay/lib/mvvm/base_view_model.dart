import '../l10n/display_text.dart';
import '../navigation/app_page.dart';
import '../navigation/app_page_transition.dart';
import 'dispose_bag.dart';
import 'error_tracker.dart';
import 'loading_tracker.dart';

/// 提供导航、重建和资源释放能力的基础 ViewModel。
abstract class BaseViewModel {
  final disposeBag = DisposeBag();

  Future<Object?> Function(AppPage page, [AppPageTransition? transition])?
  showPage;
  Future<Object?> Function(AppPage page)? pushReplacementPage;
  Future<Object?> Function(AppPage page)? replaceRootPage;
  Future<Object?> Function(AppPage page, String untilRouteName)?
  pushAndRemoveUntilPage;
  void Function([Object? result])? popPage;
  void Function(String routeName)? popUntilPage;
  void Function()? popToRootPage;
  void Function([Object? result])? popPageUseRoot;
  void Function()? rebuild;

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

  Future<Object?> replaceRoot(AppPage page) {
    return replaceRootPage?.call(page) ?? Future.value(null);
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

/// 在基础能力上增加 Loading、错误追踪和短消息输出。
abstract class AppBaseViewModel extends BaseViewModel {
  final loadingTracker = LoadingTracker();
  final errorTracker = ErrorTracker();

  void Function(DisplayText? message)? showSuccessMessageImpl;
  void Function(DisplayText? message)? showFailMessageImpl;
  void Function(DisplayText? message)? showNormalMessageImpl;

  /// 是否接管页面返回事件；默认关闭以保留系统原生返回和 predictive back。
  bool get hookBackButton => false;

  /// 显式接管返回事件时，返回 true 表示允许页面退出。
  Future<bool> onWillPop() async => true;

  void showSuccessMessage({DisplayText? message}) {
    showSuccessMessageImpl?.call(message);
  }

  void showFailMessage({DisplayText? message}) {
    showFailMessageImpl?.call(message);
  }

  void showNormalMessage({DisplayText? message}) {
    showNormalMessageImpl?.call(message);
  }

  @override
  void dispose() {
    loadingTracker.dispose();
    errorTracker.dispose();
    super.dispose();
  }
}

/// 组合应用默认的 Loading 跟踪与错误消费策略。
extension LoadingAndErrorTrack<T> on Future<T> {
  Future<T?> trackLoadingAndConsumeError(AppBaseViewModel viewModel) {
    return trackLoading(
      viewModel.loadingTracker,
    ).consumeError(viewModel.errorTracker);
  }
}
