---
name: flutter-mvvm-api-dev
description: >-
  在已有 Flutter MVVM 项目中接入协议已确认的正式 API，修改接口、Dio 实现、请求与响应模型及调用方。协议未确认时不用此 skill；纯页面和导航开发也不属于此范围。
---

# 正式 API 开发

## 开始前

- 确认项目有 `lib/app_container.dart` 和 `lib/services/api/api_service.dart`。
- 读取[文件职责](../shared-references/architecture-responsibilities.md)，再读相关 API、model、调用方和测试。
- 先确认接口路径、字段和响应结构。缺少协议时停止正式实现，说明缺少的信息。不要猜 URL、字段或响应外层格式。

## 怎么做

1. 优先扩展已有业务接口。没有合适模块时，才新建 `<domain>_api_service.dart`。
2. 沿用项目的 JSON 解析方式，默认用 `json_serializable`。解析代码放在 model 内。
3. Dio 实现复用 `ApiService` 配置好的 client，用 `.parseData(...)` 解析响应和转换 `DioException`。
4. 新模块加入 `ApiService` 默认 factory 和 `ApiService.withModules(...)`，共用已有 Dio。
5. 简单页面的 ViewModel 可以直接调用注入的业务 API 接口。需要缓存或共享数据时用 Repository；独立业务流程用业务 Service。
6. 依赖通过构造函数传入。AppContainer 创建应用级依赖，AppPage provider 取得依赖并创建 ViewModel。

## 不要这样做

- 不在 Widget 或 ViewModel 里解析 JSON。
- API Service 只对接后台，不因一个流程用了多个接口，就把整个流程放进 API。
- 不为每个接口加一层 Repository，也不把所有复杂逻辑都塞进 Repository。
- `AppContainer` 是唯一全局依赖容器。ApiService、Repository 和其他 Service 不加 `shared`。
- 参考旧代码前先检查职责，不复制已有的错误分工。

## 完成检查

- 检查本次 API、model、数据更新入口和调用方向是否符合职责分工。
- 使用 `json_serializable` 时运行 `dart run build_runner build`。
- 格式化改动文件，运行 `flutter analyze`。
- 接口、解析、错误转换、Repository、ViewModel 和依赖组装都需要行为验证。
- 先看已有测试是否直接检查了受影响的输入、动作、状态、输出或接口约定。只是执行到了代码不算覆盖。
- 已覆盖就复跑并说明依据；没覆盖才补最小测试。

## 按需阅读

- 新增或扩展 API：读 [API 模式](references/api-service-pattern.md)。
- 新增 model 或修改解析：读 [Model 模式](references/model-pattern.md)。
