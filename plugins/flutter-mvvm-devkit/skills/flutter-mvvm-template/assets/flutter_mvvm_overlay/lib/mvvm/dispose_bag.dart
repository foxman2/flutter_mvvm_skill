import 'dart:async';

abstract class Disposable {
  const Disposable();

  void dispose();

  void disposeBy(DisposeBag disposeBag) {
    disposeBag.add(dispose);
  }
}

typedef DisposeAction = void Function();

class AnonymousDisposable extends Disposable {
  const AnonymousDisposable(this.disposeAction);

  final DisposeAction disposeAction;

  @override
  void dispose() {
    disposeAction();
  }
}

class DisposeBag extends Disposable {
  final List<DisposeAction> _disposables = [];

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

extension StreamSubscriptionDispose on StreamSubscription<dynamic> {
  void disposeBy(DisposeBag disposeBag) {
    disposeBag.add(cancel);
  }
}
