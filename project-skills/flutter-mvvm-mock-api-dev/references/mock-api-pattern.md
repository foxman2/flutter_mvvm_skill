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

- `lib/services/api/`：已确认 API 的正式 contract/真实 Dio 实现；未确认 domain 只临时放 contract 和 `Unimplemented<Domain>ApiService`。
- `lib/services/mock_api/`：临时 mock service。
- `lib/services/mock_api/models/`：后台未确认、只服务 mock 的临时 model。
- `lib/models/`：已确认 model。

## Service 写法

后台协议未确认但前端必须先开发时，创建临时 contract 和不依赖 Dio 的明确占位实现。未确认 response shape 使用 mock-only model，不猜正式 URL、字段或 envelope：

```dart
import '../mock_api/models/mock_order_summary.dart';

abstract class OrderApiService {
  Future<List<MockOrderSummary>> fetchOrders();
}

class UnimplementedOrderApiService implements OrderApiService {
  const UnimplementedOrderApiService();

  @override
  Future<List<MockOrderSummary>> fetchOrders() {
    return Future<List<MockOrderSummary>>.error(
      UnimplementedError('Backend order list API is not confirmed.'),
    );
  }
}
```

不要为未确认 domain 创建 `DioOrderApiService`。后台确认后，用 `$flutter-mvvm-api-dev` 把 mock-only model 迁移成正式 model，并用真实 Dio 实现替换占位类。

## Mock 实现

```dart
import '../api/order_api_service.dart';
import 'models/mock_order_summary.dart';

class MockOrderApiService implements OrderApiService {
  const MockOrderApiService();

  @override
  Future<List<MockOrderSummary>> fetchOrders() async {
    return const [
      MockOrderSummary(id: 'mock-order-1', title: 'Mock Order'),
    ];
  }
}
```

只有 response shape 已确认且项目已有正式 model 时才复用 `lib/models/`。否则先创建 `MockOrderSummary` 到 `lib/services/mock_api/models/`，并让临时 contract、mock service 和调用方统一使用这个 mock-only model；后台确认后再迁移到正式 model。

## ApiService 切换

在 `ApiService.setup()` 中集中切换：

```dart
if (_apiEnvironment == ApiEnvironment.mock) {
  _order = const MockOrderApiService();
  return;
}

_order = const UnimplementedOrderApiService();
```

开发时需要 mock 环境，使用 `flutter run --dart-define=server=mock`。不要为了预览直接修改代码中的默认环境。

不要在 ViewModel 中判断 mock/real：

```dart
final orders = await ApiService.shared.order
    .fetchOrders()
    .trackLoadingAndConsumeError(this);
```

## 测试

- 静态 fixture 直接返回、简单必填字段赋值和无分支 mock-only model 默认不测试。
- 修改环境组装逻辑时，覆盖 `ApiService.shared.setup()` 的 mock wiring，并确认 mock 模式不触发 Dio adapter。
- mock 包含延迟、错误、分页、状态切换或复杂列表解析时，只覆盖对应的非平凡行为。
- 后台确认后，由正式 API 的实际解析、异常或 contract 风险决定是否补测试，不机械生成 happy/error 两套用例。
