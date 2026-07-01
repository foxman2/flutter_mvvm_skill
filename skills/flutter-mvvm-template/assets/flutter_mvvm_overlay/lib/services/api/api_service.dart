import 'dart:async';

import 'package:dio/dio.dart';

import 'api_service_config.dart';
import 'user_api_service.dart';

class ApiService {
  ApiService._();

  static final ApiService shared = ApiService._();

  UserApiService? _user;

  UserApiService get user {
    final service = _user;
    if (service == null) {
      throw StateError('ApiService.shared.setup() must be called before use.');
    }
    return service;
  }

  void setup(ApiServiceConfig config, {Dio? dio}) {
    final client = dio ?? Dio();
    client.options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      headers: Map<String, dynamic>.from(config.headers),
    );
    client.interceptors.clear();

    final headerProvider = config.headerProvider;
    if (headerProvider != null) {
      client.interceptors.add(_DynamicHeaderInterceptor(headerProvider));
    }

    if (config.enableLog) {
      client.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    _user = UserApiService(client);
  }
}

class _DynamicHeaderInterceptor extends Interceptor {
  _DynamicHeaderInterceptor(this._headerProvider);

  final ApiHeaderProvider _headerProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Future.sync(_headerProvider)
        .then((headers) {
          options.headers.addAll(headers);
          handler.next(options);
        })
        .catchError((Object error, StackTrace stackTrace) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: error,
              stackTrace: stackTrace,
              type: DioExceptionType.unknown,
            ),
          );
        });
  }
}
