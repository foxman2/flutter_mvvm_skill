import 'package:dio/dio.dart';

import 'api_service_exception.dart';

extension ApiServiceResponseFuture<T> on Future<Response<T>> {
  Future<R> parseData<R>(R Function(T data) parser) {
    return then<R>(
      (response) => parser(response.data as T),
      onError: (Object error, StackTrace stackTrace) {
        if (error is DioException) {
          final exception = ApiServiceException.fromDioException(error);
          Error.throwWithStackTrace(exception, error.stackTrace);
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }
}
