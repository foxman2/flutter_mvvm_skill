import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../errors/app_exception.dart';

class ErrorTracker {
  final _subject = PublishSubject<AppException>(sync: true);

  Stream<AppException> get stream => _subject.stream;

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

extension ErrorTrack<T> on Future<T> {
  Future<T> trackError(ErrorTracker tracker) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      tracker.onError(error, stackTrace);
      rethrow;
    }
  }

  Future<T?> consumeError(ErrorTracker tracker) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      tracker.onError(error, stackTrace);
      return null;
    }
  }
}
