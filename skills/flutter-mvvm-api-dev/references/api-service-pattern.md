# API Service 模式

## 目录和命名

```text
lib/services/api/
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
- 入口：`ApiService.shared.<domain>`

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

在 `api_service.dart` 中：

```dart
enum ApiEnvironment { production, test, mock }

const ApiEnvironment _apiEnvironment = ApiEnvironment.production;

class ApiService {
  ApiService._();

  static final ApiService shared = ApiService._();

  UserApiService? _user;
  OrderApiService? _order;

  UserApiService get user => _user ?? _notSetUp();
  OrderApiService get order => _order ?? _notSetUp();

  void setup() {
    if (_apiEnvironment == ApiEnvironment.mock) {
      _user = const MockUserApiService();
      _order = const MockOrderApiService();
      return;
    }

    final client = Dio(
      BaseOptions(
        baseUrl: _apiBaseUrlFor(_apiEnvironment),
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        headers: Map<String, dynamic>.from(_staticHeaders),
      ),
    );
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(_dynamicHeaders);
          handler.next(options);
        },
      ),
    );
    _user = DioUserApiService(client);
    _order = DioOrderApiService(client);
  }

  Duration get _connectTimeout => const Duration(seconds: 15);

  Duration get _receiveTimeout => const Duration(seconds: 15);

  Duration get _sendTimeout => const Duration(seconds: 15);

  Map<String, String> get _staticHeaders => const {};

  Map<String, String> get _dynamicHeaders => const {};

  Never _notSetUp() {
    throw StateError('ApiService.shared.setup() must be called before use.');
  }
}
```

业务模块持有配置好的 Dio，不持有 `ApiService`。

## 方法规则

- GET 查询参数使用 Dio 的 `queryParameters`，不要手拼 query string。
- POST/PUT body 使用 model 的 `toJson()` 或简单 `Map<String, dynamic>`。
- 使用 `.parseData(...)` 统一解析 `response.data` 并把 `DioException` 转换为 `ApiServiceException`。
- response data 的空值或字段缺失由 parser/model 按业务语义处理。
- 不在 API service 中处理 UI loading、toast、弹窗或页面跳转。
- 未确认的 mock-only model 不进入 `lib/models/`；改用 `$flutter-mvvm-mock-api-dev`。

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
