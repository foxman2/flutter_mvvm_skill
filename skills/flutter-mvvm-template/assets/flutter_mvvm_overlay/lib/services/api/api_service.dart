import 'package:dio/dio.dart';

import '../mock_api/mock_user_api_service.dart';
import 'user_api_service.dart';

enum ApiEnvironment { production, test, mock }

// Edit this value in the generated project to switch API environments.
const ApiEnvironment _apiEnvironment = ApiEnvironment.production;

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
        baseUrl: _apiBaseUrlFor(_apiEnvironment),
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

String _apiBaseUrlFor(ApiEnvironment environment) {
  switch (environment) {
    case ApiEnvironment.production:
      return const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    case ApiEnvironment.test:
      return const String.fromEnvironment('API_TEST_BASE_URL', defaultValue: '');
    case ApiEnvironment.mock:
      return '';
  }
}
