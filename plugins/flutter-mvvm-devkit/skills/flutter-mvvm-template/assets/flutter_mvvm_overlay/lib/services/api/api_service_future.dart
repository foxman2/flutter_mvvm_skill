import 'package:dio/dio.dart';

import 'api_service_exception.dart';

/// 解析 Dio 响应，并将 DioException 统一映射为 [ApiServiceException]。
extension ApiServiceResponseFuture<T> on Future<Response<T>> {
  /// 使用 [parser] 将响应 data 转为业务模型，同时保留原错误堆栈。
  Future<R> parseData<R>(R Function(T data) parser) {
    return then<R>(
      (response) => parser(response.data as T),
      onError: (Object error, StackTrace stackTrace) {
        if (error is DioException) {
          final exception = ApiServiceException.fromDioException(
            error,
            stackTrace,
          );
          Error.throwWithStackTrace(exception, stackTrace);
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }
}
