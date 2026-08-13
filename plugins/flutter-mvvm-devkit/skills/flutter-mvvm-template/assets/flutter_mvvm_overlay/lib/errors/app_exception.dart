abstract class AppException implements Exception {
  const AppException({
    required this.message,
    required this.stackTrace,
    this.title,
  });

  final String? title;
  final String message;
  final StackTrace stackTrace;

  @override
  String toString() => '$runtimeType(title: $title, message: $message)';
}

final class GeneralAppException extends AppException {
  GeneralAppException({
    required super.message,
    super.title,
    StackTrace? stackTrace,
  }) : super(stackTrace: stackTrace ?? StackTrace.current);

  factory GeneralAppException.from(Object error, StackTrace stackTrace) {
    return GeneralAppException(
      message: error.toString(),
      stackTrace: stackTrace,
    );
  }
}
