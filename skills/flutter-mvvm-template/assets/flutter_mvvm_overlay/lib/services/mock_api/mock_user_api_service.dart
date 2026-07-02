import '../../data/models/user/user_profile.dart';
import '../api/user_api_service.dart';

class MockUserApiService implements UserApiService {
  const MockUserApiService();

  @override
  Future<UserProfile> fetchProfile() async {
    return const UserProfile(id: 'mock-user', name: 'Mock User');
  }
}
