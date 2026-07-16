# Mock API 与 AppContainer 模式

下文用 `Order` 演示一个后台尚未确认的新 domain。`Order` 不是模板预置模块；实际开发
时替换为项目中的真实 domain，不要因为示例而创建订单相关代码。

## 目录边界

```text
lib/
├── app_container.dart
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

- `lib/services/api/`：聚合 `ApiService`、domain contract 和真实 Dio 实现；未确认 domain 先放可调用的临时 contract 和 `Unimplemented<Domain>ApiService`。
- `lib/services/mock_api/`：临时 mock service。
- `lib/services/mock_api/models/`：后台未确认、只服务 mock 的临时 model。
- `lib/models/`：已确认 model。
- `lib/app_container.dart`：唯一全局依赖入口和 composition root，不属于 Service 层。

## Service contract 与占位实现

后台协议未确认但前端必须先开发时，先创建可供调用方使用的临时 contract，以及供
非 mock 环境 fail-fast 的无 Dio 占位实现：

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

这里已经提供了 `<Domain>ApiService` contract（示例中的 `OrderApiService`）；mock
环境由 `Mock<Domain>ApiService` 实现，并通过聚合 `ApiService.<domain>` 暴露给调用方。
协议未确认时不要编造的是 `Dio<Domain>ApiService` 的 URL、请求字段和响应解析，不是
不要提供 ApiService。

## Mock 实现

```dart
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

只有 response shape 已确认且项目已有正式 model 时才复用 `lib/models/`。否则把
临时结构放进 `lib/services/mock_api/models/`，并让 contract、mock service 和调用方
统一使用；后台确认后再迁移。

## ApiService 实例组装

在 ApiService 默认 factory 中集中切换，所有 domain 字段保持 final：

```dart
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
    order: const UnimplementedOrderApiService(),
  );
}

ApiService.withModules({required this.user, required this.order});

final UserApiService user;
final OrderApiService order;
```

这样 mock 阶段和真实接入阶段共享 `OrderApiService` contract 与
`ApiService.order` 入口。页面/ViewModel 不依赖具体实现，后续迁移无需修改调用方式。

开发时使用 `flutter run --dart-define=server=mock`。不要为了预览修改默认环境，也不要
在 ViewModel 中判断 mock/real：

```dart
final orders = await AppContainer.shared.apiService.order
    .fetchOrders()
    .trackLoadingAndConsumeError(this);
```

## 测试

修改环境 wiring 时，构造完整替代容器并整体交换：

```dart
final replacement = AppContainer(
  apiService: ApiService(environment: ApiEnvironment.mock),
);

AppContainer.replaceForTesting(replacement);
try {
  expect(
    AppContainer.shared.apiService.order,
    isA<MockOrderApiService>(),
  );
} finally {
  AppContainer.restore();
}
```

- 确认 mock factory 分支不创建 Dio adapter。
- 静态 fixture、简单必填字段和无分支 mock-only model 默认不测试。
- mock 包含延迟、错误、分页、状态切换或复杂列表解析时，只覆盖对应行为。
- 不修改独立 Service 或 Repository 的静态状态；这些类型不应存在全局实例。

## 后台确认后的迁移

使用 `$flutter-mvvm-api-dev` 对齐已有 contract，把 mock-only model 迁移为正式 model，
新增 `Dio<Domain>ApiService`，并在非 mock 分支用它替换
`Unimplemented<Domain>ApiService`。`Mock<Domain>ApiService` 可以继续用于本地预览和
测试；聚合 `ApiService.<domain>` 及页面/ViewModel 的调用方式保持不变。
