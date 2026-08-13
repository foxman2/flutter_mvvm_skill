import '../../models/user/user_profile.dart';
import '../api/user_api_service.dart';

/// 返回稳定本地数据的用户 API Mock 实现。
class MockUserApiService implements UserApiService {
  const MockUserApiService();

  @override
  Future<UserProfile> fetchProfile() async {
    return const UserProfile(id: 'mock-user', name: 'Mock User');
  }
}
