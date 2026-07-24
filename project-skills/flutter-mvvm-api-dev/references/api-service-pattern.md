# API Service 与 AppContainer 模式

## 目录和入口

```text
lib/
├── app_container.dart
├── repositories/
│   └── user_repository.dart
└── services/
    └── api/
        ├── api_service.dart
        ├── api_service_exception.dart
        ├── api_service_future.dart
        ├── user_api_service.dart
        └── order_api_service.dart
```

新增业务域时：

- 文件：`<domain>_api_service.dart`
- 正式接口：`<Domain>ApiService`
- 真实网络实现：`Dio<Domain>ApiService`
- 业务入口：`AppContainer.shared.apiService.<domain>`

ApiService、Repository 和其他 Service 都是普通实例，不声明 `shared`。只有
AppContainer 是全局依赖入口。

## 新增模块

业务 service 文件同时包含 contract 和 Dio 实现：

```dart
import 'package:dio/dio.dart';

import '../../models/order/order_summary.dart';
import 'api_service_future.dart';

abstract class OrderApiService {
  Future<List<OrderSummary>> fetchOrders();
}

class DioOrderApiService implements OrderApiService {
  DioOrderApiService(this._dio);

  final Dio _dio;

  @override
  Future<List<OrderSummary>> fetchOrders() {
    return _dio.get<List<dynamic>>('/orders').parseData((data) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .toList();
    });
  }
}
```

在 `api_service.dart` 的默认 factory 中一次性组装所有 final 模块：

```dart
enum ApiEnvironment { production, test, mock }

extension ApiEnvironmentBaseUrl on ApiEnvironment {
  String get baseUrl {
    switch (this) {
      case ApiEnvironment.production:
        return 'https://api.example.com';
      case ApiEnvironment.test:
        return 'https://test-api.example.com';
      case ApiEnvironment.mock:
        return '';
    }
  }
}

const ApiEnvironment defaultApiEnvironment = ApiEnvironment.production;
const String _server = String.fromEnvironment('server');
final ApiEnvironment _apiEnvironment = resolveApiEnvironment(
  server: _server,
  isReleaseMode: kReleaseMode,
);

class ApiService {
  factory ApiService({ApiEnvironment? environment}) {
    final selectedEnvironment = environment ?? _apiEnvironment;
    if (selectedEnvironment == ApiEnvironment.mock) {
      return ApiService.withModules(
        user: const MockUserApiService(),
        order: const MockOrderApiService(),
      );
    }

    final client = _createDio(selectedEnvironment);
    return ApiService.withModules(
      user: DioUserApiService(client),
      order: DioOrderApiService(client),
    );
  }

  ApiService.withModules({required this.user, required this.order});

  final UserApiService user;
  final OrderApiService order;

  static Dio _createDio(ApiEnvironment environment) {
    final client = Dio(
      BaseOptions(
        baseUrl: environment.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    return client;
  }
}
```

通过 `--dart-define=server=production|test|mock` 选择环境。有效显式参数在所有构建
模式下优先；无效或缺失参数在 Release 回退 production，在 Debug/Profile 回退
`defaultApiEnvironment`。production 和 test 地址直接配置在
`ApiEnvironmentBaseUrl` 中。

所有真实业务模块共享默认 factory 创建的同一个 Dio。`withModules(...)` 只做显式
对象组装，不读取环境，也不维护可变 setup 状态。

## AppContainer 与 Repository

新增需要贯穿 App 生命周期的 Repository 时，把它注册到 AppContainer，并只在这个
composition root 内传递依赖：

```dart
class UserRepository {
  UserRepository({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  Future<UserProfile> fetchProfile() {
    return _apiService.user.fetchProfile();
  }
}

static Future<void> setup() async {
  final apiService = ApiService();
  _shared = AppContainer(
    apiService: apiService,
    userRepository: UserRepository(apiService: apiService),
  );
}
```

AppContainer 构造函数和 final 字段要同步加入 `userRepository`。ViewModel 不接收
ApiService 或 Repository 构造参数，直接读取
`AppContainer.shared.userRepository`；简单调用可读取
`AppContainer.shared.apiService.user`。

## ViewModel 调用

```dart
class ProfileViewModel extends ProfileViewModelType {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _profile = await AppContainer.shared.apiService.user
        .fetchProfile()
        .trackLoadingAndConsumeError(this);
    makeRebuild();
  }

  @override
  UserProfile? get profile => _profile;
}
```

## 测试替换

测试不要修改独立 Service 或 Repository 的静态状态。先创建完整替代容器，再整体替换：

```dart
final replacement = AppContainer(
  apiService: ApiService.withModules(
    user: const MockUserApiService(),
    order: const MockOrderApiService(),
  ),
);

AppContainer.replaceForTesting(replacement);
try {
  // Exercise business behavior through AppContainer.shared.
} finally {
  AppContainer.restore();
}
```

## 方法规则

- GET 查询参数使用 Dio 的 `queryParameters`，不要手拼 query string。
- POST/PUT body 优先使用 model 的 `toJson()`；推荐由 `json_serializable` 生成，也可遵循项目已有序列化方案。没有对应 model 的简单场景可使用 `Map<String, dynamic>`。
- 使用 `.parseData(...)` 解析 `response.data` 并转换 `DioException`。
- 不在 API service 中处理 UI loading、toast、弹窗或页面跳转。
- 未确认的 mock-only model 不进入 `lib/models/`；改用 `$flutter-mvvm-mock-api-dev`。
