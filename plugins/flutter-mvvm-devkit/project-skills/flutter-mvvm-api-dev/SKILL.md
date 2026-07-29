---
name: flutter-mvvm-api-dev
description: >-
  在已有 Flutter MVVM 项目中开发协议已确认的正式后端 API，包括 domain contract、Dio 实现、request/response model、Repository/ViewModel 接入，以及把现有临时数据实现迁移为正式实现。用于路径、字段和响应结构已经确认的接口；不用于协议未确认的临时实现、纯页面或导航开发，或新增和修改测试。
---

# Flutter MVVM API Dev

## 工作流程

1. 确认项目包含 `lib/app_container.dart` 和 `lib/services/api/api_service.dart`，并读取最接近的 API 模块、model、调用方和测试。
2. 扩展已有 domain contract；只有没有合适模块时才新增 `<domain>_api_service.dart`。
3. 沿用项目序列化方案；默认使用 `json_serializable`，并把字段解析限制在 model 内。
4. 让 Dio 实现复用 `ApiService` 配置的 client，通过 `.parseData(...)` 统一解析数据和转换 `DioException`。
5. 通过构造函数把 domain service 或 repository 注入 ViewModel；对应 AppPage provider 从 `AppContainer.shared` 取得依赖并完成组装。
6. 采用 `json_serializable` 时运行 `dart run build_runner build`，再格式化、运行 `flutter analyze` 和受影响的已有测试；不在本工作流中新增或修改测试。

## 关键边界

- 只实现路径、字段和响应结构已经确认的接口；不猜测 URL、字段或统一 response envelope。
- `AppContainer` 是唯一全局依赖入口；ApiService、Repository 和其他 Service 不声明 `shared`。
- 新 domain 由 `ApiService` 默认 factory 使用同一个配置好的 Dio 组装，并同步加入 `ApiService.withModules(...)`。
- Widget 和 ViewModel 不解析 JSON；复杂业务可通过普通 Repository 封装。
- 协议、字段或响应结构未确认时停止实现并报告缺失信息，不固化猜测出的 contract。

## 读取参考

- 新增或扩展 API 模块：读 `references/api-service-pattern.md`。
- 新增 request/response model 或自定义解析：读 `references/model-pattern.md`。
