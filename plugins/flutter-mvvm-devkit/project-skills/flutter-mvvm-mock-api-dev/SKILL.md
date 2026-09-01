---
name: flutter-mvvm-mock-api-dev
description: >-
  在已有 Flutter MVVM 项目中新增、迁移或审查用户可见的演示业务数据，并通过临时 domain contract、mock service、mock-only model、无 Dio 的 Unimplemented 占位实现和 ApiService wiring 提供数据。用于后端协议未确认的前端先行开发、正式页面和 Product Preview；不用于已确认协议的真实 Dio API、纯 UI 状态或静态展示资源。
---

# Flutter MVVM Mock API Dev

## 数据原则

- 所有用户可见的演示业务数据都由 domain API contract 的 Mock 实现返回，包括正式页面、Product Preview 和测试入口使用的账号、列表、详情、状态、价格、额度、消息、结果与记录。
- Widget、Page、ViewModel 和 `lib/product_preview/` 只保存输入、选中、展开、步骤、筛选和 loading 等纯 UI 状态，不直接声明业务 fixture、demo entity 或演示业务常量。
- l10n 文案、theme token、图标、静态资源路径和不代表服务端数据的展示枚举不进入 Mock API。

## 工作流程

1. 确认项目包含 `lib/app_container.dart` 和 `lib/services/api/api_service.dart`，读取现有 real/mock 模块、相关调用方和测试；迁移存量数据时同时搜索 Page、ViewModel、Screen、`product_preview`、model 和测试中的 fixture、demo、seed 及硬编码业务实体。
2. 区分业务演示数据与纯 UI 状态，按现有业务领域复用或建立 contract；不要为每个页面创建一套 API。
3. 在 `lib/services/api/<domain>_api_service.dart` 提供稳定 contract，以及非 mock 环境 fail-fast、且不依赖 Dio 的 `Unimplemented<Domain>ApiService`。
4. 在 `lib/services/mock_api/mock_<domain>_api_service.dart` 实现 contract；复用已确认 model，未确认结构放入 `lib/services/mock_api/models/`，可按需求模拟延迟、空结果、错误或状态分支。
5. 只在 `ApiService` 组装层根据现有环境开关选择 Mock、Unimplemented 或已有 Dio 实现；生产调用代码不直接 import `services/mock_api/`，Widget 和 ViewModel 不判断 mock/real。
6. 由 AppPage provider 从 `AppContainer.shared.apiService.<domain>` 取得 contract，并通过构造函数注入正式或预览 ViewModel；预览 ViewModel 只保留交互状态。
7. 迁移完成后确认原调用方不再保存业务 fixture，Mock 环境仍可完成目标演示，非 mock 环境对未确认协议明确 fail-fast。
8. 把新增 contract、wiring、mock service 和 mock-only model 标记为待开发审核；格式化并运行 `flutter analyze`；domain contract、mock 返回、非 mock fail-fast、wiring 和调用方全部属于非视觉改动，先检查已有测试是否直接断言受影响的输入、动作、状态、输出或 contract，仅执行到相关代码不算直接覆盖；覆盖充分时复跑并记录依据，覆盖不足时才新增或更新最小测试。
9. 后端协议确认后停止本工作流，记录 contract 对齐、model 迁移和非 mock 分支实现需求，改用正式 API 开发流程，不在此处新增真实 Dio 实现。

## 关键边界

- 不猜测真实 URL、字段、响应 envelope 或错误码，也不创建伪装成真实实现的 `Dio<Domain>ApiService`。
- 不通过测试固化未确认的真实 URL、字段、响应 envelope 或错误码；只覆盖临时 domain 行为、Mock 场景和组装边界。
- ApiService、mock service 和 Repository 不声明 `shared`；Mock 只模拟接口返回，不处理 loading、toast、导航或持久化。
- 使用项目已有的 mock 环境机制，不为 Product Preview 改默认环境或把环境分支写入业务代码。
- Product Preview 可以保存流程和控件状态，但套餐、价格、机构、消息等业务演示数据必须来自 Mock API。
- 后端协议确认后不继续扩展临时结构，也不把未审核 model 直接迁入正式目录。

## 读取参考

- 新增或迁移演示数据、创建临时 model、接入 Product Preview 或执行正式迁移前，读 `references/mock-api-pattern.md`。
