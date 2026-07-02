---
name: flutter-mvvm-api-dev
description: 在已有 Flutter MVVM 项目中新增或修改已确认的正式网络 API、ApiService 业务模块、Dio service 实现、普通 Dart model 的 fromJson/toJson、repository/ViewModel 调用和接口测试。Use when working inside a Flutter MVVM app generated from flutter-mvvm-template and adding confirmed API endpoints, request/response models, service modules, or wiring API calls into ViewModels.
---

# Flutter MVVM API Dev

使用这个 skill 在已有 Flutter MVVM 项目里开发已确认的正式网络接口：新增 API service contract 和 Dio 实现、补 model 解析、接入 repository 或 ViewModel，并保持和模板里的 `ApiService.shared` 写法一致。

## 适用场景

- 用户要求“新增接口”“接一个 API”“写 user/order/product service”“补请求/响应 model”“把接口接到 ViewModel”，且后端路径/字段已确认。
- 当前项目包含 `lib/services/api/api_service.dart`，并通过 `ApiService.shared` 统一发起请求。
- 用户希望继续使用模板内置 Dio 基础层，而不是引入 Retrofit、Chopper、freezed 或其他 codegen。

如果接口或 model 还没有被后台确认，只需要前端先行 mock，使用 `$flutter-mvvm-mock-api-dev`。
如果任务主要是创建页面、接导航、改 UI 或抽组件，使用 `$flutter-mvvm-feature-dev`。

## 工作流程

1. 先读当前项目结构：`pubspec.yaml`、`lib/services/api/`、`lib/data/models/`、相关 `lib/pages/<feature>/` 和测试。
2. 找到最接近的 API service 模块；已有模块就追加 contract 方法和 Dio 实现，没有模块才新增 `<domain>_api_service.dart`。
3. 请求/响应数据结构放在 `lib/data/models/<domain>/`，先用普通 Dart model 和手写 `fromJson/toJson`。
4. Dio service 方法直接使用构造函数传入的 Dio 发请求，并通过 `.parseData(...)` 统一转换 `DioException` 和调用 model 的 `fromJson`。
5. ViewModel 不直接解析 JSON；简单场景可直接调 `ApiService.shared.<domain>`，复杂场景优先经 repository。
6. 完成后运行项目已有检查；通常是 `dart format lib test`、`flutter analyze`，相关逻辑补 `flutter test`。

## 读取参考

- 新增或扩展 API 模块：读 `references/api-service-pattern.md`。
- 新增 request/response model 和解析：读 `references/model-pattern.md`。

## 开发约定

- 统一入口是 `ApiService.shared`，不要创建新的 `ApiClient`、`network/` 单例或并行 Dio 全局对象。
- 业务 contract 命名为 `<Domain>ApiService`，真实网络实现命名为 `Dio<Domain>ApiService`，文件命名为 `<domain>_api_service.dart`，入口形态为 `ApiService.shared.user.fetchProfile()`。
- 新增模块时，在 `ApiService` 中创建私有模块字段，并在真实分支用配置好的 Dio 初始化为 `Dio<Domain>ApiService(client)`。
- 接口路径和方法名语义清楚，例如 `fetchProfile()`、`updateProfile()`、`fetchOrders()`。
- 不默认引入 Retrofit、Chopper、freezed、json_serializable、build_runner；用户明确要求时再单独规划。
- 不预设统一响应 envelope，例如 `{code, message, data}`；如果项目已有协议，跟随现有封装。
- 不把后台未确认的 mock-only model 放进 `lib/data/models/`；这类需求交给 `$flutter-mvvm-mock-api-dev`。

## 输出标准

- API contract、Dio 实现、model、repository/ViewModel 的职责分开，JSON 解析不散落到 Widget 中。
- 新增接口能复用 `ApiServiceException`、baseUrl、静态/动态 headers 和 timeout 配置。
- model 字段类型明确，`fromJson` 对可空字段和列表做必要防御。
- 测试覆盖新增 model 解析和至少一条 API service happy path 或错误路径。
