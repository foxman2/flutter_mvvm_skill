import 'package:rxdart/rxdart.dart';

class LoadingTracker {
  final _activeCount = BehaviorSubject<int>.seeded(0, sync: true);

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

  void increment() {
    _activeCount.add(_activeCount.value + 1);
  }

  void decrement() {
    if (_activeCount.value > 0) {
      _activeCount.add(_activeCount.value - 1);
    }
  }

  void dispose() {
    _activeCount.close();
  }
}

extension LoadingTrack<T> on Future<T> {
  Future<T> trackLoading(LoadingTracker tracker) {
    tracker.increment();
    return whenComplete(tracker.decrement);
  }
}
