import 'dart:async';

/// 可显式释放资源的统一协议。
abstract class Disposable {
  const Disposable();

  void dispose();

  /// 将当前对象的释放动作交给 [disposeBag] 托管。
  void disposeBy(DisposeBag disposeBag) {
    disposeBag.add(dispose);
  }
}

/// 无参数的资源释放动作。
typedef DisposeAction = void Function();

/// 将任意回调包装成可释放对象。
class AnonymousDisposable extends Disposable {
  const AnonymousDisposable(this.disposeAction);

  final DisposeAction disposeAction;

  @override
  void dispose() {
    disposeAction();
  }
}

/// 按注册顺序的逆序批量释放资源，重复调用不会再次执行旧动作。
class DisposeBag extends Disposable {
  final List<DisposeAction> _disposables = [];

  /// 注册一个待释放动作。
  void add(DisposeAction disposeAction) {
    _disposables.add(disposeAction);
  }

  @override
  void dispose() {
    final actions = List<DisposeAction>.from(_disposables);
    _disposables.clear();
    for (final action in actions.reversed) {
      action();
    }
  }
}

/// 让 Stream 订阅可直接加入 [DisposeBag]。
extension StreamSubscriptionDispose on StreamSubscription<dynamic> {
  void disposeBy(DisposeBag disposeBag) {
    disposeBag.add(cancel);
  }
}
