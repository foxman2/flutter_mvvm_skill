/// 应用层统一错误模型，携带可展示信息和原始堆栈。
abstract class AppException implements Exception {
  const AppException({
    required this.message,
    required this.stackTrace,
    this.title,
  });

  final String? title;
  final String? message;
  final StackTrace stackTrace;

  @override
  String toString() => '$runtimeType(title: $title, message: $message)';
}

/// 将未分类异常包装成应用可消费的通用错误。
final class GeneralAppException extends AppException {
  GeneralAppException({
    required super.message,
    super.title,
    StackTrace? stackTrace,
  }) : super(stackTrace: stackTrace ?? StackTrace.current);

  /// 保留原异常文本和捕获位置，构造通用应用错误。
  factory GeneralAppException.from(Object error, StackTrace stackTrace) {
    return GeneralAppException(
      message: error.toString(),
      stackTrace: stackTrace,
    );
  }
}
