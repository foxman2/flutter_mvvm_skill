import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../l10n/display_text.dart';
import '../navigation/app_navigator.dart';
import '../navigation/app_page.dart';
import '../navigation/app_page_transition.dart';
import '../pages/alert/alert_view_model.dart';
import '../widgets/app_loading_dialog.dart';
import '../widgets/app_toast.dart';
import 'base_view_model.dart';
import 'dispose_bag.dart';

/// 页面创建 ViewModel 的延迟工厂。
typedef ViewModelProvider<T extends BaseViewModel> = T Function();

/// 负责持有 ViewModel 的基础 StatefulWidget。
abstract class BaseStatefulView<ViewModel extends BaseViewModel>
    extends StatefulWidget {
  const BaseStatefulView({super.key, required this.viewModelProvider});

  final ViewModelProvider<ViewModel> viewModelProvider;

  ViewModel createViewModel() => viewModelProvider();
}

/// 创建、绑定并释放 ViewModel，同时为其接入通用导航能力。
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

/// 使用应用级 Loading、错误和短消息能力的页面别名。
typedef AppBaseStatefulPage<ViewModel extends AppBaseViewModel> =
    BaseStatefulView<ViewModel>;

/// 在基础页面绑定之上接入 Loading、错误弹窗和 Toast 展示。
abstract class AppBaseStatefulPageState<
  ViewModel extends AppBaseViewModel,
  T extends AppBaseStatefulPage<ViewModel>
>
    extends BaseStatefulViewState<ViewModel, T> {
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
    // 页面销毁时仅移除自己的 owner，其他页面仍在加载时不会误关 Dialog。
    AppLoadingDialogController.shared.detach(this);
    super.dispose();
  }

  /// 将显式启用的页面返回决策转发给 ViewModel。
  Future<bool> onWillPop() => viewModel.onWillPop();

  void _updateLoadingState(bool isLoading) {
    AppLoadingDialogController.shared.update(
      owner: this,
      isLoading: isLoading,
      context: context,
    );
  }

  void _handleError(AppException error) {
    final alert = AlertViewModel(
      title: error.title == null ? null : .raw(error.title!),
      content: error.message == null ? null : .raw(error.message!),
    )..addAction(.localized((strings) => strings.commonOk), isDefault: true);
    _show(AlertAppPage(alert));
  }

  void _showSuccessMessage(DisplayText? message) {
    AppToastController.shared.show(
      context,
      type: AppToastType.success,
      message: message?.resolve(context) ?? '',
    );
  }

  void _showFailMessage(DisplayText? message) {
    AppToastController.shared.show(
      context,
      type: AppToastType.fail,
      message: message?.resolve(context) ?? '',
    );
  }

  void _showNormalMessage(DisplayText? message) {
    AppToastController.shared.show(
      context,
      type: AppToastType.normal,
      message: message?.resolve(context) ?? '',
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Widget createWidget(BuildContext context) {
    final child = createWidget2(context);
    // 默认保留系统原生返回；只有 ViewModel 明确开启时才安装 PopScope。
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

  /// 构建页面自身内容，通用交互包装由基类统一处理。
  Widget createWidget2(BuildContext context);
}
