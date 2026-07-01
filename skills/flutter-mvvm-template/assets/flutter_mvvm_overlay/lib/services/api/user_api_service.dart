import 'package:dio/dio.dart';

import '../../data/models/user/user_profile.dart';
import 'api_service_future.dart';

class UserApiService {
  UserApiService(this._dio);

  final Dio _dio;

  Future<UserProfile> fetchProfile() {
    return _dio
        .get<Map<String, dynamic>>('/user/profile')
        .parseData(UserProfile.fromJson);
  }
}
