import 'package:rxdart/rxdart.dart';

class AppError implements Exception {
  AppError({this.title, this.message, StackTrace? stackTrace})
    : stackTrace = stackTrace ?? StackTrace.current;

  final String? title;
  final String? message;
  final StackTrace? stackTrace;

  factory AppError.from(Object error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      return error;
    }
    return AppError(message: error.toString(), stackTrace: stackTrace);
  }
}

class ErrorTracker {
  final _subject = PublishSubject<AppError>(sync: true);

  Stream<AppError> get stream => _subject.stream;

  void onError(Object error, [StackTrace? stackTrace]) {
    _subject.add(AppError.from(error, stackTrace));
  }

  void dispose() {
    _subject.close();
  }
}

extension ErrorTrack<T> on Future<T> {
  Future<T> trackError(ErrorTracker tracker) {
    return catchError((Object error, StackTrace stackTrace) {
      tracker.onError(error, stackTrace);
      throw error;
    });
  }

  Future<T?> consumeError(ErrorTracker tracker) {
    return then<T?>(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) {
        tracker.onError(error, stackTrace);
        return null;
      },
    );
  }
}
