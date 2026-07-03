import 'package:dio/dio.dart';

class ApiServiceException implements Exception {
  const ApiServiceException({
    required this.message,
    this.statusCode,
    this.path,
    this.originalError,
    this.stackTrace,
  });

  final String message;
  final int? statusCode;
  final String? path;
  final Object? originalError;
  final StackTrace? stackTrace;

  factory ApiServiceException.fromDioException(DioException error) {
    return ApiServiceException(
      message: _messageFor(error),
      statusCode: error.response?.statusCode,
      path: error.requestOptions.path,
      originalError: error,
      stackTrace: error.stackTrace,
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
  String toString() => message;
}
