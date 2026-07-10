---
name: flutter-mvvm-mock-api-dev
description: >-
  用于已有 flutter-mvvm-template 架构项目中的后端未确认或前端先行 mock API 开发：新增或修改 mock service、mock-only model、ApiService mock 切换、预览/原型临时数据和 mock 测试，并保持外部调用仍走 ApiService.shared。不用于已确认真实后端 API；使用 flutter-mvvm-api-dev。不用于纯页面/UI/导航/组件工作；隔离预览 UI 使用 flutter-mvvm-pm-ui，正式功能 UI 使用 flutter-mvvm-feature-dev。
---

# Flutter MVVM Mock API Dev

使用这个 skill 在已有 Flutter MVVM 项目里开发 mock API。mock API 用来支持前端先行开发，正式 API 入口保持稳定，未被后台确认的实现和 model 先放在临时目录。

## 职责边界

- 只处理后台未确认时的 mock service、mock-only model、ApiService mock 切换和 mock 测试。
- 支持隔离预览或前端先行开发所需的临时 mock 数据，但新增 contract、wiring 和 mock-only model 必须在输出中标记待开发审核。
- 当前项目应包含 `lib/services/api/api_service.dart`，并通过 `ApiService.shared` 统一访问 API。
- 项目应使用模板里的 `ApiEnvironment.mock` 或类似代码级环境开关切换 mock/real。

## 工作流程

1. 先读当前项目结构：`lib/services/api/`、`lib/services/mock_api/`、`lib/models/`、相关页面/ViewModel 和测试。
2. 正式接口定义放在 `lib/services/api/<domain>_api_service.dart`；如果还没有对应 domain，新增 abstract service 和 Dio 实现。
3. mock 实现放在 `lib/services/mock_api/mock_<domain>_api_service.dart`，并实现正式 service 接口。
4. 能使用正式 model 时优先使用 `lib/models/<domain>/`；后台未确认的新结构放在 `lib/services/mock_api/models/`。
5. 在 `ApiService.setup()` 里通过当前环境是否为 `ApiEnvironment.mock` 选择 mock service 或 Dio service，不在 ViewModel/Widget 里写 mock 分支。
6. 预览或原型场景中，把新增的 service contract、mock service、mock-only model 和 `ApiService` wiring 记录为待开发审核。
7. 补测试：mock service happy path、必要的 mock-only model 解析；使用 `--dart-define=server=mock` 覆盖 `ApiService.shared.setup()` 的 wiring。
8. 后台确认后，把临时 model 合并到 `lib/models/<domain>/`，再用 `$flutter-mvvm-api-dev` 补真实 Dio 请求。

## 读取参考

- 新增 mock API、临时 model 和迁移规则：读 `references/mock-api-pattern.md`。

## 开发约定

- 外部调用保持 `ApiService.shared.<domain>.<method>()`，不要新增并行的 `MockApiService.shared`。
- mock service 类命名为 `Mock<Domain>ApiService`，文件命名为 `mock_<domain>_api_service.dart`，直接放在 `lib/services/mock_api/`。
- mock 数据只模拟接口返回，不处理 UI loading、toast、弹窗或导航。
- 不猜测后台 URL、字段名或统一响应 envelope；未确认内容用 mock-only model 明确隔离。
- mock 只在 `ApiService` 组装层切换，ViewModel 和 Widget 不感知 mock/real。
- 本地预览优先使用 `flutter run --dart-define=server=mock` 切换 mock，不为了预览直接改正式逻辑分支。

## 输出标准

- mock 代码和未确认 model 有清楚临时边界。
- 已确认 model 不重复定义，直接复用正式 model。
- 真实 API 入口和调用方式不变。
- 后台确认后能按目录迁移，不需要大范围重写页面或 ViewModel。
