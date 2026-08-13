import 'services/api/api_service.dart';

/// 保存应用级依赖，并在启动完成后通过 [shared] 提供统一访问入口。
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

  /// 初始化应用运行所需的依赖；必须在读取 [shared] 前调用。
  static Future<void> setup() async {
    _shared = AppContainer(apiService: ApiService());
  }
}
