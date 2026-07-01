import 'dart:async';

typedef ApiHeaderProvider = FutureOr<Map<String, String>> Function();

class ApiServiceConfig {
  const ApiServiceConfig({
    this.baseUrl = '',
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.headers = const {},
    this.headerProvider,
    this.enableLog = false,
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final Map<String, String> headers;
  final ApiHeaderProvider? headerProvider;
  final bool enableLog;
}
