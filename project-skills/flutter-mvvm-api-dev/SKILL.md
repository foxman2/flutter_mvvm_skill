---
name: flutter-mvvm-api-dev
description: >-
  用于已有 flutter-mvvm-template 架构项目中的已确认正式后端 API 开发：新增或修改由 AppContainer 管理的 ApiService 业务模块、Dio 实现、推荐使用 json_serializable 的 request/response model、repository/ViewModel 调用，并在后端协议确认后把已审核的 mock/preview 数据迁移为正式 API/model。不用于后端未确认、前端先行 mock 或临时预览数据；使用 flutter-mvvm-mock-api-dev。不用于纯页面/UI/导航/组件工作；使用 flutter-mvvm-feature-dev 或 flutter-mvvm-pm-ui。
---

# Flutter MVVM API Dev

使用这个 skill 在已有 Flutter MVVM 项目里开发已确认的正式网络接口：新增 API service contract 和 Dio 实现、补 model 解析、接入 repository 或 ViewModel，并保持 App 级依赖统一由 `AppContainer.shared` 提供。

## 职责边界

- 只处理已确认的正式 API、正式 model、service contract、Dio 实现和调用接入。
- 只有后端字段、路径和响应确认后，才把预览或 mock-only 数据迁移成正式 API/model。
- 当前项目应包含 `lib/app_container.dart` 和 `lib/services/api/api_service.dart`，并通过 `AppContainer.shared.apiService` 统一发起请求。
- 不为未确认接口猜 URL、字段或响应 envelope；这类需求先做 mock。

## 工作流程

1. 先读当前项目结构：`pubspec.yaml`、`lib/app_container.dart`、`lib/services/api/`、`lib/repositories/`（如存在）、`lib/models/`、相关 `lib/pages/<feature>/` 和测试。
2. 找到最接近的 API service 模块；已有模块就追加 contract 方法和 Dio 实现，没有模块才新增 `<domain>_api_service.dart`。
3. 请求/响应 model 推荐使用 `json_serializable`：添加 `@JsonSerializable()` 和对应的 `part`，让 `fromJson/toJson` 委托给生成函数。项目已有稳定序列化方案时沿用现有约定，避免并行引入另一套方案。
4. Dio service 方法直接使用构造函数传入的 Dio 发请求，并通过 `.parseData(...)` 统一转换 `DioException` 和调用 model 的 `fromJson`。
5. ViewModel 不直接解析 JSON；简单场景可直接调 `AppContainer.shared.apiService.<domain>`，复杂场景优先调用注册在 AppContainer 中的 repository。
6. 采用 `json_serializable` 时，在新增或修改 JSON model 后运行 `dart run build_runner build --delete-conflicting-outputs`；随后格式化本次改动文件并运行 `flutter analyze`，先运行覆盖受影响 contract 的已有测试。
7. 只为复杂解析/转换、错误映射、重要请求分支或回归问题新增针对性测试。简单字段直映射和无分支 wiring 默认不新增测试；交付时说明新增测试对应的风险，或说明本次无需新增测试的理由。

## 读取参考

- 新增或扩展 API 模块：读 `references/api-service-pattern.md`。
- 新增 request/response model 和解析：读 `references/model-pattern.md`。

## 开发约定

- 唯一全局入口是 `AppContainer.shared`；ApiService、Repository 和其他 Service 不声明 `shared` 或并行全局对象。
- 业务 contract 命名为 `<Domain>ApiService`，真实网络实现命名为 `Dio<Domain>ApiService`，文件命名为 `<domain>_api_service.dart`，入口形态为 `AppContainer.shared.apiService.user.fetchProfile()`。
- 新增模块时，在 `ApiService` 中增加 final 模块字段，并在默认 factory 中用同一个配置好的 Dio 一次性组装；同步更新 `ApiService.withModules(...)` 以支持显式测试组装。
- 复杂业务使用普通 Repository 实例；需要贯穿 App 生命周期时，在 AppContainer composition root 中创建并注册。允许 AppContainer 在组装时把 ApiService 构造注入 Repository，但不要通过 AppPage、Page 或 ViewModel 构造函数传递 App 级依赖。
- 测试构造完整替代 AppContainer，使用 `replaceForTesting()` 安装并在 tearDown/finally 中 `restore()`；不要逐个重配置 Service 或 Repository。
- 接口路径和方法名语义清楚，例如 `fetchProfile()`、`updateProfile()`、`fetchOrders()`。
- JSON model 推荐使用 `json_annotation`、`json_serializable` 和 `build_runner`；采用时补齐缺少的依赖、保留生成的 `.g.dart` 文件，并且不直接修改生成文件。
- 项目已有其他序列化方案时遵循现有架构；如采用手写 `fromJson/toJson`，字段映射只留在 model 内，不散落到 API service、ViewModel 或 Widget。
- 不预设统一响应 envelope，例如 `{code, message, data}`；如果项目已有协议，跟随现有封装。
- 不把后台未确认的 mock-only model 放进 `lib/models/`；这类需求交给 `$flutter-mvvm-mock-api-dev`。
- 不把临时预览数据直接提升为正式 API；先确认后端协议，再迁移。

## 输出标准

- API contract、Dio 实现、model、repository/ViewModel 的职责分开，JSON 解析不散落到 Widget 中。
- 新增接口能复用 `ApiServiceException`、baseUrl、静态/动态 headers 和 timeout 配置。
- model 字段类型明确；采用 `json_serializable` 时，缺失值、可空字段、字段改名和自定义转换通过 `JsonKey` 或 `JsonConverter` 显式声明。
- 一个代表性 contract 测试可以同时覆盖 method、path、body 和 response parsing，不要按文件或 happy/error 分类机械拆测试。
- `json_serializable` 生成的简单 DTO 直映射默认不测试；只有默认值、可空兼容、嵌套集合、自定义转换、异常映射或回归风险需要针对性覆盖。
