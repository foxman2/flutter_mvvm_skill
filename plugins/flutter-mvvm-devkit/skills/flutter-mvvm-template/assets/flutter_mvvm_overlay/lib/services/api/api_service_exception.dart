import 'package:dio/dio.dart';

import '../../errors/app_exception.dart';

/// 将 Dio 网络异常转换为包含状态码和请求路径的应用错误。
class ApiServiceException extends AppException {
  const ApiServiceException({
    super.title,
    required super.message,
    required super.stackTrace,
    this.statusCode,
    this.path,
  });

  final int? statusCode;
  final String? path;

  /// 保留 Dio 请求上下文并生成面向用户的错误信息。
  factory ApiServiceException.fromDioException(
    DioException error,
    StackTrace stackTrace,
  ) {
    return ApiServiceException(
      message: _messageFor(error),
      statusCode: error.response?.statusCode,
      path: error.requestOptions.path,
      stackTrace: stackTrace,
    );
  }

  static String _messageFor(DioException error) {
    final responseMessage = _messageFromData(error.response?.data);
    if (responseMessage != null) {
      return responseMessage;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Request timed out.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          return 'Request failed with status code $statusCode.';
        }
        return 'Request failed.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Network connection failed.';
      case DioExceptionType.badCertificate:
        return 'Network certificate is invalid.';
      case DioExceptionType.unknown:
        return error.message ?? 'Network request failed.';
    }
  }

  static String? _messageFromData(Object? data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return null;
  }

  @override
  String toString() {
    return '$runtimeType('
        'title: $title, '
        'message: $message, '
        'statusCode: $statusCode, '
        'path: $path)';
  }
}
