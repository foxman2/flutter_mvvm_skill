# Mock API 审核边界

PM 预览需要业务形态数据时优先新增或复用 mock API，但这类改动是待开发审核的临时实现。

PM skill 可以同时使用 `$flutter-mvvm-mock-api-dev` 并按其规则修改临时 contract、`ApiService` wiring、mock service 和 mock-only model；这不授权实现已确认的正式 API/model 或真实 Dio 请求。

## 使用方式

- 遵循 `$flutter-mvvm-mock-api-dev` 的目录和命名规则。
- mock service 放在 `lib/services/mock_api/`。
- 后台未确认的数据结构放在 `lib/services/mock_api/models/`。
- 外部调用仍走 `ApiService.shared.<domain>.<method>()`，不要新增并行 mock 单例。
- 本地运行 mock 时优先使用 `--dart-define=server=mock`。
- 如果项目已有对应 mock service，`product_preview` 页面 ViewModel 应优先调用它，不要再硬编码一份业务形态列表或详情数据。

## 必须标记待审核

新增或修改以下文件时，在输出说明里列入“待开发审核”：

- `lib/services/api/<domain>_api_service.dart`
- `lib/services/api/api_service.dart`
- `lib/services/mock_api/mock_<domain>_api_service.dart`
- `lib/services/mock_api/models/**`
- 任何为了 PM 预览临时新增的 request/response 类型

## 不要做

- 不猜正式 URL、字段名、响应 envelope 或错误码。
- 不把 mock-only model 放进 `lib/models/`。
- 不把 mock 分支写进 Widget 或 ViewModel。
- 不在 `product_preview` 页面 ViewModel 中长期硬编码可由 mock API 表达的列表、卡片、详情或状态数据。
- 不把 PM mock 改动当成后端已确认的正式 API。

后台确认后，用 `$flutter-mvvm-api-dev` 把临时 contract、mock-only model 和 `Unimplemented<Domain>ApiService` 迁移为正式 model 与 Dio 实现。
