import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../errors/app_exception.dart';

/// 统一记录并广播 ViewModel 异步流程中的应用错误。
class ErrorTracker {
  final _subject = PublishSubject<AppException>(sync: true);

  Stream<AppException> get stream => _subject.stream;

  /// 将任意异常转换为 [AppException]，记录后推送给 UI 层。
  void onError(Object error, [StackTrace? stackTrace]) {
    final exception = error is AppException
        ? error
        : GeneralAppException.from(error, stackTrace ?? StackTrace.current);
    _log(exception);
    _subject.add(exception);
  }

  void dispose() {
    _subject.close();
  }

  void _log(AppException exception) {
    debugPrint('$exception');
    debugPrint('App exception stack trace:\n${exception.stackTrace}');
  }
}

/// 为 Future 提供统一的错误上报和消费能力。
extension ErrorTrack<T> on Future<T> {
  /// 上报错误并保留原错误与堆栈继续抛出。
  Future<T> trackError(ErrorTracker tracker) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      tracker.onError(error, stackTrace);
      rethrow;
    }
  }

  /// 上报错误后返回 null，适用于错误已由 UI 统一展示的流程。
  Future<T?> consumeError(ErrorTracker tracker) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      tracker.onError(error, stackTrace);
      return null;
    }
  }
}
