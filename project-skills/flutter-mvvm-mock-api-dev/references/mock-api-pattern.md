# Mock API 模式

## 目录边界

```text
lib/
├── models/
│   └── user/
│       └── user_profile.dart
└── services/
    ├── api/
    │   ├── api_service.dart
    │   └── order_api_service.dart
    └── mock_api/
        ├── mock_order_api_service.dart
        └── models/
            └── mock_order_summary.dart
```

- `lib/services/api/`：正式 API contract 和真实 Dio 实现。
- `lib/services/mock_api/`：临时 mock service。
- `lib/services/mock_api/models/`：后台未确认、只服务 mock 的临时 model。
- `lib/models/`：已确认 model。

## Service 写法

正式接口和 Dio 实现放在同一个 domain service 文件：

```dart
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

后台路径未确认但前端必须先开发时，保留正式接口方法；Dio 实现可以先返回明确的未实现错误，不要猜 URL：

```dart
@override
Future<List<OrderSummary>> fetchOrders() {
  return Future<List<OrderSummary>>.error(
    UnimplementedError('Backend order list API is not confirmed.'),
  );
}
```

## Mock 实现

```dart
class MockOrderApiService implements OrderApiService {
  const MockOrderApiService();

  @override
  Future<List<OrderSummary>> fetchOrders() async {
    return const [
      OrderSummary(id: 'mock-order-1', title: 'Mock Order'),
    ];
  }
}
```

如果 response shape 未确认，先创建 `MockOrderSummary` 到 `lib/services/mock_api/models/`，并让 contract、mock service 和临时调用方统一使用这个 mock-only model；后台确认后再迁移到正式 model。

## ApiService 切换

在 `ApiService.setup()` 中集中切换：

```dart
if (_apiEnvironment == ApiEnvironment.mock) {
  _order = const MockOrderApiService();
  return;
}

_order = DioOrderApiService(client);
```

开发时需要 mock 环境，直接把 `api_service.dart` 顶部的 `_apiEnvironment` 改成 `ApiEnvironment.mock`。

不要在 ViewModel 中判断 mock/real：

```dart
final orders = await ApiService.shared.order
    .fetchOrders()
    .trackLoadingAndConsumeError(this);
```

## 测试

- mock service 返回期望数据。
- 如果项目当前环境常量已经切到 mock，`ApiService.shared.setup()` 会组装 mock service。
- mock 模式不触发 Dio adapter。
- mock-only model 至少覆盖必填字段和列表解析。
- 后台确认后，补真实 Dio happy path 或错误路径测试。
