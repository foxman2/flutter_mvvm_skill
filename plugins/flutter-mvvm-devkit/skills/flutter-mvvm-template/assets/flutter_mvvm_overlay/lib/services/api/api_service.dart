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

// Debug and profile builds use this when --dart-define=server is omitted.
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
  if (isReleaseMode) {
    return ApiEnvironment.production;
  }

  switch (server) {
    case 'production':
      return ApiEnvironment.production;
    case 'test':
      return ApiEnvironment.test;
    case 'mock':
      return ApiEnvironment.mock;
    case '':
      return defaultEnvironment;
    default:
      return ApiEnvironment.production;
  }
}

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

  void setup() {
    if (_apiEnvironment == ApiEnvironment.mock) {
      _user = const MockUserApiService();
      return;
    }

    final client = Dio(
      BaseOptions(
        baseUrl: _apiEnvironment.baseUrl,
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

    _user = DioUserApiService(client);
  }

  Duration get _connectTimeout => const Duration(seconds: 15);

  Duration get _receiveTimeout => const Duration(seconds: 15);

  Duration get _sendTimeout => const Duration(seconds: 15);

  Map<String, String> get _staticHeaders => const {};

  Map<String, String> get _dynamicHeaders => const {};
}
