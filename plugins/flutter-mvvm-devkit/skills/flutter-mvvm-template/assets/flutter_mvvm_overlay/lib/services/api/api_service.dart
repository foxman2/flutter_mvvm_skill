import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../mock_api/mock_user_api_service.dart';
import 'user_api_service.dart';

/// 应用可连接的服务环境。
enum ApiEnvironment { production, test, mock }

/// 为每个真实服务环境提供基础地址。
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

// Debug/Profile 未提供或错误配置 --dart-define=server 时使用该默认值。
const ApiEnvironment defaultApiEnvironment = ApiEnvironment.production;

const String _server = String.fromEnvironment('server');
final ApiEnvironment _apiEnvironment = resolveApiEnvironment(
  server: _server,
  isReleaseMode: kReleaseMode,
);

/// 按编译参数和构建模式选择环境；Release 始终对非法值回退生产环境。
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

/// 聚合各业务 API 模块，并根据环境装配真实或 Mock 实现。
class ApiService {
  factory ApiService({ApiEnvironment? environment}) {
    final selectedEnvironment = environment ?? _apiEnvironment;
    if (selectedEnvironment == ApiEnvironment.mock) {
      return ApiService.withModules(user: const MockUserApiService());
    }

    final client = _createDio(selectedEnvironment);
    return ApiService.withModules(user: DioUserApiService(client));
  }

  /// 允许测试或上层容器显式注入 API 模块。
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
