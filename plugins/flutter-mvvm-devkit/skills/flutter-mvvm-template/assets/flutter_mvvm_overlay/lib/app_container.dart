import 'services/api/api_service.dart';

class AppContainer {
  AppContainer({required this.apiService});

  final ApiService apiService;

  static AppContainer? _shared;

  static AppContainer get shared {
    final container = _shared;
    if (container == null) {
      throw StateError('AppContainer.setup() must be called before use.');
    }
    return container;
  }

  static Future<void> setup() async {
    _shared = AppContainer(apiService: ApiService());
  }
}
