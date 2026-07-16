---
name: flutter-mvvm-mock-api-dev
description: >-
  用于已有 flutter-mvvm-template 架构项目中的后端未确认或前端先行 mock API 开发：新增或修改临时 service contract、mock service、mock-only model、Unimplemented real 占位实现、ApiService mock 实例组装和预览/原型临时数据，并保持外部调用统一走 AppContainer。占位 real 分支不依赖 Dio，也不猜 URL、字段或响应协议。不用于已确认真实后端 API；使用 flutter-mvvm-api-dev。不用于纯页面/UI/导航/组件工作；隔离预览 UI 使用 flutter-mvvm-pm-ui，正式功能 UI 使用 flutter-mvvm-feature-dev。
---

# Flutter MVVM Mock API Dev

使用这个 skill 在已有 Flutter MVVM 项目里开发 mock API。mock API 用来支持前端先行开发，正式 API 入口保持稳定，未被后台确认的实现和 model 先放在临时目录。

## 职责边界

- 为后台未确认的 domain 提供可供调用方使用的临时 `<Domain>ApiService` contract、`Mock<Domain>ApiService`、mock-only model、非 mock 分支的 `Unimplemented<Domain>ApiService` 占位实现和聚合 `ApiService` 实例组装。
- 支持隔离预览或前端先行开发所需的临时 mock 数据，但新增 contract、wiring 和 mock-only model 必须在输出中标记待开发审核。
- 当前项目应包含 `lib/app_container.dart` 和 `lib/services/api/api_service.dart`，并通过 `AppContainer.shared.apiService` 统一访问 API。
- 项目应使用模板里的 `ApiEnvironment.mock` 或类似代码级环境开关切换 mock/real。

## 工作流程

1. 先读当前项目结构：`lib/app_container.dart`、`lib/services/api/`、`lib/services/mock_api/`、`lib/models/`、相关页面/ViewModel 和测试。
2. 临时接口定义放在 `lib/services/api/<domain>_api_service.dart`；如果还没有对应 domain，新增可供页面/ViewModel 稳定调用的 abstract service contract，以及不依赖 Dio 的 `Unimplemented<Domain>ApiService`。contract 的未确认部分标记待审核，不提前编造真实 Dio 请求。
3. mock 实现放在 `lib/services/mock_api/mock_<domain>_api_service.dart`，并实现对应的临时或已确认 service contract。
4. 能使用正式 model 时优先使用 `lib/models/<domain>/`；后台未确认的新结构放在 `lib/services/mock_api/models/`。
5. 在 `ApiService` 默认 factory 中通过当前环境是否为 `ApiEnvironment.mock` 一次性组装 mock service 或 `Unimplemented<Domain>ApiService`；已有已确认 domain 在非 mock 分支继续使用其 Dio service，不在 ViewModel/Widget 里写 mock 分支。
6. 预览或原型场景中，把新增的 service contract、mock service、mock-only model 和 `ApiService` wiring 记录为待开发审核。
7. 格式化本次改动文件并运行 `flutter analyze`，再运行覆盖受影响行为的已有测试。只有修改环境 wiring，或 mock 包含延迟、错误、状态分支、复杂解析或回归风险时才新增测试；静态 fixture 直接返回默认不测。交付时说明新增测试对应的风险，或说明本次无需新增测试的理由。
8. 后台确认后，用 `$flutter-mvvm-api-dev` 对齐已有 contract、把临时 model 合并到 `lib/models/<domain>/`、新增真实 Dio 实现，并只替换非 mock 分支的占位 wiring；调用方继续使用同一个 `ApiService` 入口。

## 读取参考

- 新增 mock API、临时 model 和迁移规则：读 `references/mock-api-pattern.md`。

## 开发约定

- 外部调用保持 `AppContainer.shared.apiService.<domain>.<method>()`；ApiService、mock service 和 Repository 都不声明 `shared` 或其他全局实例。
- mock service 类命名为 `Mock<Domain>ApiService`，文件命名为 `mock_<domain>_api_service.dart`，直接放在 `lib/services/mock_api/`。
- mock 阶段就创建 `<Domain>ApiService` contract，并把 `Mock<Domain>ApiService` 接入聚合 `ApiService`；禁止的是在协议未确认时编造 `Dio<Domain>ApiService` 的 URL、字段和解析，不是禁止提供 ApiService。
- 未确认 domain 的非 mock 占位类命名为 `Unimplemented<Domain>ApiService`；不要让它持有 Dio，也不要用 `Dio<Domain>ApiService` 名称伪装成真实网络实现。
- mock 数据只模拟接口返回，不处理 UI loading、toast、弹窗或导航。
- 不猜测后台 URL、字段名或统一响应 envelope；未确认内容用 mock-only model 明确隔离。
- mock 只在 `ApiService` 组装层切换，ViewModel 和 Widget 不感知 mock/real。
- 修改 wiring 测试时，用 mock ApiService 构造完整 AppContainer，通过 `replaceForTesting()` 整体替换并在 tearDown/finally 中 `restore()`；不要逐个重配置 service。
- 本地预览优先使用 `flutter run --dart-define=server=mock` 切换 mock，不为了预览直接改正式逻辑分支。

## 输出标准

- mock 代码和未确认 model 有清楚临时边界。
- 已确认 model 不重复定义，直接复用正式 model。
- mock 阶段已经提供稳定的 domain contract 和聚合 `ApiService` 入口；接入真实 API 时调用方式不变。
- 后台确认后能按目录迁移，不需要大范围重写页面或 ViewModel。
- 测试只覆盖非平凡 mock 行为或 wiring 风险，不按 service、model 或返回方法数量机械生成。
