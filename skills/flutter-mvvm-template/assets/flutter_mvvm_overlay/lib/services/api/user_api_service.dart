import 'package:dio/dio.dart';

import '../../models/user/user_profile.dart';
import 'api_service_future.dart';

/// 用户域 API 契约。
abstract class UserApiService {
  Future<UserProfile> fetchProfile();
}

/// 基于 Dio 的用户域 API 实现。
class DioUserApiService implements UserApiService {
  DioUserApiService(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> fetchProfile() {
    return _dio
        .get<Map<String, dynamic>>('/user/profile')
        .parseData(UserProfile.fromJson);
  }
}
