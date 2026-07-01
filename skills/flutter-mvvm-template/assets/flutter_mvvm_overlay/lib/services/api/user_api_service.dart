import 'package:dio/dio.dart';

import '../../data/models/user/user_profile.dart';
import 'api_service_exception.dart';

class UserApiService {
  UserApiService(this._dio);

  final Dio _dio;

  Future<UserProfile> fetchProfile() async {
    const path = '/user/profile';
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) {
        throw const ApiServiceException(
          message: 'Response data is empty.',
          path: path,
        );
      }
      return UserProfile.fromJson(data);
    } on DioException catch (error) {
      throw ApiServiceException.fromDioException(error);
    }
  }
}
