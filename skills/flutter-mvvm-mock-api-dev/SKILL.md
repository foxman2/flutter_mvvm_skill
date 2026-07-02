---
name: flutter-mvvm-mock-api-dev
description: 在已有 Flutter MVVM 项目中新增或修改 mock API、临时 mock service、mock-only model、ApiService mock 切换和 mock 测试。Use when working inside a Flutter MVVM app generated from flutter-mvvm-template and adding temporary backend-unconfirmed mock endpoints without polluting formal models.
---

# Flutter MVVM Mock API Dev

使用这个 skill 在已有 Flutter MVVM 项目里开发 mock API。mock API 用来支持前端先行开发，正式 API 入口保持稳定，未被后台确认的实现和 model 先放在临时目录。

## 适用场景

- 用户要求“先写 mock 接口”“后台还没好，先模拟数据”“新增 mock API”“临时 model 先别进正式目录”。
- 当前项目包含 `lib/services/api/api_service.dart`，并通过 `ApiService.shared` 统一访问 API。
- 项目使用模板里的 `ApiEnvironment.mock` 或类似代码级环境开关切换 mock/real。

如果用户要接已确认的真实后端接口，使用 `$flutter-mvvm-api-dev`。

## 工作流程

1. 先读当前项目结构：`lib/services/api/`、`lib/services/mock_api/`、`lib/data/models/`、相关页面/ViewModel 和测试。
2. 正式接口定义放在 `lib/services/api/<domain>_api_service.dart`；如果还没有对应 domain，新增 abstract service 和 Dio 实现。
3. mock 实现放在 `lib/services/mock_api/mock_<domain>_api_service.dart`，并实现正式 service 接口。
4. 能使用正式 model 时优先使用 `lib/data/models/<domain>/`；后台未确认的新结构放在 `lib/services/mock_api/models/`。
5. 在 `ApiService.setup()` 里通过当前环境是否为 `ApiEnvironment.mock` 选择 mock service 或 Dio service，不在 ViewModel/Widget 里写 mock 分支。
6. 补测试：mock service happy path、必要的 mock-only model 解析；如果项目当前环境常量已经切到 mock，再覆盖 `ApiService.shared.setup()` 的 wiring。
7. 后台确认后，把临时 model 合并到 `lib/data/models/<domain>/`，再用 `$flutter-mvvm-api-dev` 补真实 Dio 请求。

## 读取参考

- 新增 mock API、临时 model 和迁移规则：读 `references/mock-api-pattern.md`。

## 开发约定

- 外部调用保持 `ApiService.shared.<domain>.<method>()`，不要新增并行的 `MockApiService.shared`。
- mock service 类命名为 `Mock<Domain>ApiService`，文件命名为 `mock_<domain>_api_service.dart`，直接放在 `lib/services/mock_api/`。
- mock 数据只模拟接口返回，不处理 UI loading、toast、弹窗或导航。
- 不猜测后台 URL、字段名或统一响应 envelope；未确认内容用 mock-only model 明确隔离。
- mock 只在 `ApiService` 组装层切换，ViewModel 和 Widget 不感知 mock/real。

## 输出标准

- mock 代码和未确认 model 有清楚临时边界。
- 已确认 model 不重复定义，直接复用正式 model。
- 真实 API 入口和调用方式不变。
- 后台确认后能按目录迁移，不需要大范围重写页面或 ViewModel。
