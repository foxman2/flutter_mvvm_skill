import 'package:rxdart/rxdart.dart';

/// 通过活跃任务计数聚合并发 Loading 状态。
class LoadingTracker {
  final _activeCount = BehaviorSubject<int>.seeded(0, sync: true);

  /// 仅在“无任务”和“有任务”之间切换时发出状态，避免并发计数变化重复刷新 UI。
  ValueStream<bool> get isLoading {
    if (_activeCount.hasValue) {
      return _activeCount
          .map((count) => count > 0)
          .distinct()
          .skip(1)
          .shareValueSeeded(_activeCount.value > 0);
    }
    return _activeCount.map((count) => count > 0).distinct().shareValue();
  }

  /// 登记一个新的活跃任务。
  void increment() {
    _activeCount.add(_activeCount.value + 1);
  }

  /// 结束一个活跃任务；计数不会降到零以下。
  void decrement() {
    if (_activeCount.value > 0) {
      _activeCount.add(_activeCount.value - 1);
    }
  }

  void dispose() {
    _activeCount.close();
  }
}

/// 将 Future 生命周期自动登记到 [LoadingTracker]。
extension LoadingTrack<T> on Future<T> {
  Future<T> trackLoading(LoadingTracker tracker) {
    tracker.increment();
    return whenComplete(tracker.decrement);
  }
}
