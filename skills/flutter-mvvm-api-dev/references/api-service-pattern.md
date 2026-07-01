# API Service 模式

## 目录和命名

```text
lib/services/api/
├── api_service.dart
├── api_service_config.dart
├── api_service_exception.dart
├── user_api_service.dart
└── order_api_service.dart
```

新增业务域时：

- 文件：`<domain>_api_service.dart`
- 类：`<Domain>ApiService`
- 入口：`ApiService.shared.<domain>`

## 新增模块

在 `api_service.dart` 中：

```dart
class ApiService {
  ApiService._();

  static final ApiService shared = ApiService._();

  UserApiService? _user;
  OrderApiService? _order;

  UserApiService get user => _user ?? _notSetUp();
  OrderApiService get order => _order ?? _notSetUp();

  void setup(ApiServiceConfig config, {Dio? dio}) {
    final client = dio ?? Dio();
    // Configure baseUrl, timeouts, headers, interceptors.
    _user = UserApiService(client);
    _order = OrderApiService(client);
  }

  Never _notSetUp() {
    throw StateError('ApiService.shared.setup() must be called before use.');
  }
}
```

业务模块持有配置好的 Dio，不持有 `ApiService`：

```dart
class OrderApiService {
  OrderApiService(this._dio);

  final Dio _dio;

  Future<List<OrderSummary>> fetchOrders() async {
    try {
      final response = await _dio.get<List<dynamic>>('/orders');
      final data = response.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiServiceException.fromDioException(error);
    }
  }
}
```

## 方法规则

- GET 查询参数使用 Dio 的 `queryParameters`，不要手拼 query string。
- POST/PUT body 使用 model 的 `toJson()` 或简单 `Map<String, dynamic>`。
- response data 为 null 时，按业务语义返回空集合、null，或抛 `ApiServiceException`。
- 每个 API service 方法捕获 `DioException` 并转换为 `ApiServiceException.fromDioException(error)`。
- 不在 API service 中处理 UI loading、toast、弹窗或页面跳转。

## ViewModel 调用

ViewModel 继续使用现有 loading/error 追踪：

```dart
Future<void> loadProfile() async {
  profile = await ApiService.shared.user
      .fetchProfile()
      .trackLoadingAndConsumeError(this);
  makeRebuild();
}
```

复杂业务可以先加 repository：

```dart
class UserRepository {
  Future<UserProfile> fetchProfile() {
    return ApiService.shared.user.fetchProfile();
  }
}
```
