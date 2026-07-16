import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../mock_api/mock_user_api_service.dart';
import 'user_api_service.dart';

enum ApiEnvironment { production, test, mock }

extension ApiEnvironmentBaseUrl on ApiEnvironment {
  String get baseUrl {
    switch (this) {
      case ApiEnvironment.production:
        return 'https://api.example.com';
      case ApiEnvironment.test:
        return 'https://test-api.example.com';
      case ApiEnvironment.mock:
        return '';
    }
  }
}

// Debug and profile builds use this when --dart-define=server is omitted or invalid.
const ApiEnvironment defaultApiEnvironment = ApiEnvironment.production;

const String _server = String.fromEnvironment('server');
final ApiEnvironment _apiEnvironment = resolveApiEnvironment(
  server: _server,
  isReleaseMode: kReleaseMode,
);

ApiEnvironment resolveApiEnvironment({
  required String server,
  required bool isReleaseMode,
  ApiEnvironment defaultEnvironment = defaultApiEnvironment,
}) {
  switch (server) {
    case 'production':
      return ApiEnvironment.production;
    case 'test':
      return ApiEnvironment.test;
    case 'mock':
      return ApiEnvironment.mock;
    default:
      return isReleaseMode ? ApiEnvironment.production : defaultEnvironment;
  }
}

class ApiService {
  factory ApiService({ApiEnvironment? environment}) {
    final selectedEnvironment = environment ?? _apiEnvironment;
    if (selectedEnvironment == ApiEnvironment.mock) {
      return ApiService.withModules(user: const MockUserApiService());
    }

    final client = _createDio(selectedEnvironment);
    return ApiService.withModules(user: DioUserApiService(client));
  }

  ApiService.withModules({required this.user});

  final UserApiService user;

  static Dio _createDio(ApiEnvironment environment) {
    final client = Dio(
      BaseOptions(
        baseUrl: environment.baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        headers: Map<String, dynamic>.from(_staticHeaders),
      ),
    );
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(_dynamicHeaders);
          handler.next(options);
        },
      ),
    );
    return client;
  }

  static Duration get _connectTimeout => const Duration(seconds: 15);

  static Duration get _receiveTimeout => const Duration(seconds: 15);

  static Duration get _sendTimeout => const Duration(seconds: 15);

  static Map<String, String> get _staticHeaders => const {};

  static Map<String, String> get _dynamicHeaders => const {};
}
