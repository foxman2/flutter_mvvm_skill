# API Service 与 AppContainer 模式

## 先读项目实现

把当前项目代码作为事实来源，优先读取：

- `lib/services/api/api_service.dart`
- 最接近的 `lib/services/api/<domain>_api_service.dart`
- `lib/app_container.dart`
- 相关 Repository、ViewModel、AppPage 和测试

模板示例存在时可参考 `user_api_service.dart`；示例已被业务代码替换时，跟随最近的有效 domain 模块。

## Domain 模块

- 文件命名为 `<domain>_api_service.dart`。
- contract 命名为 `<Domain>ApiService`，真实实现命名为 `Dio<Domain>ApiService`。
- contract 和 Dio 实现可放在同一业务文件；方法名表达业务动作，如 `fetchProfile()`、`updateProfile()`。
- 通过构造函数传入 Dio；GET 参数使用 `queryParameters`，POST/PUT body 优先使用 model 的 `toJson()`。
- 使用 `.parseData(...)` 解析 `response.data` 并统一转换 `DioException`。
- 不在 API service 中处理 loading、toast、弹窗、导航或其他 UI 行为。

## ApiService 组装

- 为新 domain 增加 final 字段，并同步更新默认 factory 与 `ApiService.withModules(...)`。
- 默认 factory 为真实模块复用同一个配置好的 Dio，保留现有 baseUrl、headers、timeout 和错误处理。
- `withModules(...)` 只做显式对象组装，不读取环境或维护可变 setup 状态。
- 跟随项目已有环境解析，不为单个业务接口另建 client、全局实例或环境开关。

## Repository 与页面注入

- 简单调用可让 ViewModel 依赖具体 domain contract；需要缓存、聚合或业务编排时使用普通 Repository。
- App 生命周期 Repository 在 AppContainer composition root 中创建并注册。
- ViewModel 通过构造函数接收 Service 或 Repository；AppPage provider 从 `AppContainer.shared` 取得依赖并创建 ViewModel。
- ApiService、Repository 和其他 Service 不声明 `shared`。

## 测试

- Service、Repository 和 ViewModel 测试直接传入 fake 或显式构造的依赖。
- 一个代表性 contract 测试可同时覆盖 method、path、query/body 和 response parsing。
- 仅测试 AppContainer wiring 时整体替换容器，并在测试结束后恢复。
- 后台协议未确认时停止正式实现，改用 `$flutter-mvvm-mock-api-dev`。
