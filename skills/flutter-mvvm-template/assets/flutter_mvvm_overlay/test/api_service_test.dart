import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/data/models/user/user_profile.dart';
import 'package:{{project_name}}/services/api/api_service.dart';
import 'package:{{project_name}}/services/api/api_service_config.dart';
import 'package:{{project_name}}/services/api/api_service_exception.dart';
import 'package:{{project_name}}/services/app_services.dart';

void main() {
  test('ApiService user module requires setup', () {
    expect(() => ApiService.shared.user, throwsStateError);
  });

  test('ApiService setup applies base options and static headers', () {
    final dio = Dio();

    ApiService.shared.setup(
      const ApiServiceConfig(
        baseUrl: 'https://api.example.com',
        connectTimeout: Duration(seconds: 1),
        receiveTimeout: Duration(seconds: 2),
        sendTimeout: Duration(seconds: 3),
        headers: {'x-app': 'template'},
      ),
      dio: dio,
    );

    expect(dio.options.baseUrl, 'https://api.example.com');
    expect(dio.options.connectTimeout, const Duration(seconds: 1));
    expect(dio.options.receiveTimeout, const Duration(seconds: 2));
    expect(dio.options.sendTimeout, const Duration(seconds: 3));
    expect(dio.options.headers['x-app'], 'template');
    expect(ApiService.shared.user, isNotNull);
  });

  test('UserApiService uses shared request configuration', () async {
    RequestOptions? capturedOptions;
    final dio = Dio()
      ..httpClientAdapter = _FakeHttpClientAdapter((options) async {
        capturedOptions = options;
        return _jsonResponse({'id': '42', 'name': 'Ada'});
      });

    ApiService.shared.setup(
      ApiServiceConfig(
        baseUrl: 'https://api.example.com',
        headerProvider: () async => {'Authorization': 'Bearer token'},
      ),
      dio: dio,
    );

    final profile = await ApiService.shared.user.fetchProfile();

    expect(profile.id, '42');
    expect(profile.name, 'Ada');
    expect(
      capturedOptions?.uri.toString(),
      'https://api.example.com/user/profile',
    );
    expect(capturedOptions?.headers['Authorization'], 'Bearer token');
  });

  test(
    'UserApiService converts request failures to ApiServiceException',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter((_) async {
          return _jsonResponse({'message': 'Not found'}, statusCode: 404);
        });

      ApiService.shared.setup(const ApiServiceConfig(), dio: dio);

      await expectLater(
        ApiService.shared.user.fetchProfile(),
        throwsA(
          isA<ApiServiceException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having((error) => error.path, 'path', '/user/profile')
              .having((error) => error.message, 'message', 'Not found'),
        ),
      );
    },
  );

  test('UserProfile parses json', () {
    final profile = UserProfile.fromJson({'id': '42', 'name': 'Ada'});

    expect(profile.id, '42');
    expect(profile.name, 'Ada');
    expect(profile.toJson(), {'id': '42', 'name': 'Ada'});
  });

  test('AppServices setup completes', () async {
    await AppServices.setup();

    expect(ApiService.shared.user, isNotNull);
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
