# API 实现与依赖组装

## 先读什么

- `lib/services/api/api_service.dart`
- 最接近的 `lib/services/api/<domain>_api_service.dart`
- `lib/app_container.dart`
- 相关 Repository、ViewModel、AppPage 和测试

模板的 `user_api_service.dart` 还在时可以参考。没有相似模块，就查 API 组装和解析工具的真实接口。旧代码也要先符合[文件职责](../../shared-references/architecture-responsibilities.md)，不要照搬错误分工。

## 业务 API 模块

- 文件名用 `<domain>_api_service.dart`。
- 接口名用 `<Domain>ApiService`，真实实现用 `Dio<Domain>ApiService`，两者可以同文件。
- 方法名说明操作，例如 `fetchProfile()`、`updateProfile()`。
- Dio 通过构造函数传入。GET 参数用 `queryParameters`，POST/PUT body 优先用 model 的 `toJson()`。
- 用 `.parseData(...)` 解析 `response.data` 并转换 `DioException`。
- 每个方法对接一个后台操作。不处理 loading、toast、弹窗、导航、客户端业务决策、多接口流程或缓存。
- 后台有聚合接口就按协议接入，不在客户端编造聚合接口协议。

## ApiService 组装

- 新业务模块增加 final 字段，同步更新默认 factory 和 `ApiService.withModules(...)`。
- 默认 factory 共用已有 Dio，保留 baseUrl、headers、timeout 和错误处理。
- `withModules(...)` 只组装传入的对象，不读环境，不维护可变 setup 状态。
- 复用现有环境解析，不为单个接口另建 client、全局实例或环境开关。

## 页面怎么接入

- 为简单页面的 ViewModel 直接注入业务 API 接口。
- 需要共享数据、缓存或数据聚合时用 Repository；独立业务流程用业务 Service。不按页面数或接口数决定层数。
- 数据已有 Repository 管理时，更新经过它。
- 应用级 Repository 在 AppContainer 创建。VM、Repository 和业务 Service 都通过构造函数接收依赖，不查全局容器，不依赖具体 Mock。
- AppPage provider 从 `AppContainer.shared` 取得依赖并创建 VM。
- ApiService、Repository 和其他 Service 不加 `shared`。

协议没确认时，停止正式实现并说明缺少的路径、字段或响应结构，不创建真实 Dio 模块。
