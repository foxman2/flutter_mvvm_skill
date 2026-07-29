---
name: flutter-mvvm-mock-api-dev
description: >-
  在已有 Flutter MVVM 项目中为未确认后端协议或前端先行开发提供临时 domain contract、mock service、mock-only model、无 Dio 的 Unimplemented 占位实现和 ApiService wiring。用于尚未确认真实路径、字段或响应结构的数据接入；不用于已确认的真实 Dio API、隔离预览或正式页面 UI，或新增和修改测试。
---

# Flutter MVVM Mock API Dev

## 工作流程

1. 确认项目包含 `lib/app_container.dart` 和 `lib/services/api/api_service.dart`，并读取现有 real/mock 模块、相关调用方和测试。
2. 在 `lib/services/api/<domain>_api_service.dart` 提供稳定 contract，以及非 mock 环境 fail-fast、且不依赖 Dio 的 `Unimplemented<Domain>ApiService`。
3. 在 `lib/services/mock_api/mock_<domain>_api_service.dart` 实现 contract；复用已确认 model，未确认结构放入 `lib/services/mock_api/models/`。
4. 只在 `ApiService` 组装层根据现有环境开关选择 Mock、Unimplemented 或已有 Dio 实现，不在 Widget 或 ViewModel 中判断 mock/real。
5. 由 AppPage provider 从 `AppContainer.shared.apiService.<domain>` 取得 contract，并通过构造函数注入 ViewModel。
6. 把新增 contract、wiring、mock service 和 mock-only model 标记为待开发审核；格式化、运行 `flutter analyze` 和受影响的已有测试，不在本工作流中新增或修改测试。
7. 后端协议确认后停止本工作流，记录 contract 对齐、model 迁移和非 mock 分支实现需求，不在此处新增真实 Dio 实现。

## 关键边界

- 不猜测真实 URL、字段、响应 envelope 或错误码，也不创建伪装成真实实现的 `Dio<Domain>ApiService`。
- ApiService、mock service 和 Repository 不声明 `shared`；Mock 只模拟接口返回，不处理 loading、toast、导航或持久化。
- 使用项目已有的 mock 环境机制；不为预览改默认环境或把环境分支写入业务代码。
- 后端协议确认后不继续扩展临时结构，也不把未审核 model 直接迁入正式目录。

## 读取参考

- 新增 mock API、临时 model 或执行正式迁移：读 `references/mock-api-pattern.md`。
