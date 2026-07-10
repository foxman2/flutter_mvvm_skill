import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/models/user/user_profile.dart';
import 'package:{{project_name}}/services/api/api_service.dart';
import 'package:{{project_name}}/services/api/api_service_exception.dart';
import 'package:{{project_name}}/services/api/api_service_future.dart';
import 'package:{{project_name}}/services/api/user_api_service.dart';
import 'package:{{project_name}}/services/app_services.dart';
import 'package:{{project_name}}/services/mock_api/mock_user_api_service.dart';

void main() {
  group('resolveApiEnvironment', () {
    test('always uses production in release mode', () {
      for (final server in <String>[
        '',
        'production',
        'test',
        'mock',
        'staging',
      ]) {
        expect(
          resolveApiEnvironment(server: server, isReleaseMode: true),
          ApiEnvironment.production,
        );
      }
    });

    for (final entry in <String, ApiEnvironment>{
      'production': ApiEnvironment.production,
      'test': ApiEnvironment.test,
      'mock': ApiEnvironment.mock,
    }.entries) {
      test('accepts ${entry.key} in non-release mode', () {
        expect(
          resolveApiEnvironment(server: entry.key, isReleaseMode: false),
          entry.value,
        );
      });
    }

    test('uses the code default when non-release server is omitted', () {
      expect(
        resolveApiEnvironment(
          server: '',
          isReleaseMode: false,
          defaultEnvironment: ApiEnvironment.test,
        ),
        ApiEnvironment.test,
      );
    });

    test('uses production for unknown or differently cased servers', () {
      for (final server in <String>['staging', 'Production', 'MOCK']) {
        expect(
          resolveApiEnvironment(server: server, isReleaseMode: false),
          ApiEnvironment.production,
        );
      }
    });
  });

  test('ApiEnvironment maps directly to its configured base URL', () {
    expect(ApiEnvironment.production.baseUrl, 'https://api.example.com');
    expect(ApiEnvironment.test.baseUrl, 'https://test-api.example.com');
    expect(ApiEnvironment.mock.baseUrl, isEmpty);
  });

  test('ApiService user module requires setup', () {
    expect(() => ApiService.shared.user, throwsStateError);
  });

  test('ApiService setup creates the configured user module', () {
    ApiService.shared.setup();

    const server = String.fromEnvironment('server');
    final environment = resolveApiEnvironment(
      server: server,
      isReleaseMode: kReleaseMode,
    );
    expect(
      ApiService.shared.user,
      environment == ApiEnvironment.mock
          ? isA<MockUserApiService>()
          : isA<DioUserApiService>(),
    );
  });

  test('DioUserApiService sends profile request', () async {
    RequestOptions? capturedOptions;
    final dio = Dio()
      ..httpClientAdapter = _FakeHttpClientAdapter((options) async {
        capturedOptions = options;
        return _jsonResponse({'id': '42', 'name': 'Ada'});
      });
    final service = DioUserApiService(dio);

    final profile = await service.fetchProfile();

    expect(profile.id, '42');
    expect(profile.name, 'Ada');
    expect(capturedOptions?.uri.toString(), '/user/profile');
  });

  test('MockUserApiService returns profile without network', () async {
    const service = MockUserApiService();

    final profile = await service.fetchProfile();

    expect(profile.id, 'mock-user');
    expect(profile.name, 'Mock User');
  });

  test(
    'UserApiService converts request failures to ApiServiceException',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter((_) async {
          return _jsonResponse({'message': 'Not found'}, statusCode: 404);
        });
      final service = DioUserApiService(dio);

      await expectLater(
        service.fetchProfile(),
        throwsA(
          isA<ApiServiceException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having((error) => error.path, 'path', '/user/profile')
              .having((error) => error.message, 'message', 'Not found'),
        ),
      );
    },
  );

  test('parseData calls parser', () async {
    final profile = await Future.value(
      Response<Map<String, dynamic>>(
        data: {'id': '42', 'name': 'Ada'},
        requestOptions: RequestOptions(path: '/user/profile'),
      ),
    ).parseData(UserProfile.fromJson);

    expect(profile.id, '42');
    expect(profile.name, 'Ada');
  });

  test('parseData converts DioException to ApiServiceException', () async {
    final requestOptions = RequestOptions(path: '/user/profile');
    final dioError = DioException.badResponse(
      statusCode: 500,
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        data: {'message': 'Server error'},
        statusCode: 500,
        requestOptions: requestOptions,
      ),
    );

    await expectLater(
      Future<Response<Map<String, dynamic>>>.error(
        dioError,
      ).parseData(UserProfile.fromJson),
      throwsA(
        isA<ApiServiceException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having((error) => error.path, 'path', '/user/profile')
            .having((error) => error.message, 'message', 'Server error'),
      ),
    );
  });

  test('parseData preserves non-Dio errors', () async {
    final error = StateError('Parser failed');

    await expectLater(
      Future<Response<Map<String, dynamic>>>.error(
        error,
      ).parseData(UserProfile.fromJson),
      throwsA(same(error)),
    );
  });

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
