# Mock API 与 AppContainer 模式

## 数据归类

业务演示数据是用于模拟服务端或业务领域返回、会影响用户对产品能力理解的数据，例如：

- 用户、账号、订阅和使用额度
- 聊天任务、消息、请求状态和 AI 结果
- 机构、匹配度、地址、电话、录音元数据和 transcript
- 套餐、价格、权益、续订日期和可购买项
- 后台可配置的目录、列表、详情和业务状态

以下内容不是业务演示数据，可以保留在展示层：

- l10n 文案、theme token、图标和静态资源路径
- 当前 tab、步骤、展开、输入、筛选、选中和 loading 状态
- 不代表服务端返回的固定展示枚举

当一个值既参与业务展示又可能由后台配置时，按业务演示数据处理。不要仅根据变量名是否包含 `mock`、`fixture` 或 `demo` 判断。

## 先读项目实现

优先读取：

- `lib/services/api/api_service.dart`
- 最接近的 domain contract；模板示例存在时可参考 `user_api_service.dart`
- `lib/services/mock_api/` 下的对应实现；模板示例存在时可参考 `mock_user_api_service.dart`
- `lib/services/mock_api/models/`、调用方和测试
- 涉及 Product Preview 时读取对应 Page、ViewModel、AppPage 和 registry

迁移存量数据时，搜索 Page、ViewModel、Screen、`product_preview`、model 和测试中的业务对象、集合、价格、账号、消息、结果和记录。示例 domain 只用于理解模式，不要因为参考文件而创建无关业务代码。

## Contract 与占位实现

- 在 `lib/services/api/<domain>_api_service.dart` 定义调用方可依赖的 `<Domain>ApiService`。
- 按稳定业务动作设计 contract，不按页面拆分，也不暴露未确认的 HTTP 路径、字段或 response envelope。
- 协议未确认的非 mock 分支使用 `Unimplemented<Domain>ApiService` fail-fast。
- Unimplemented 实现不持有 Dio，也不使用 `Dio<Domain>ApiService` 名称。
- contract 的未确认部分标记待审核；不要编造 URL、字段或响应解析。

## Mock 实现与 model

- Mock 类命名为 `Mock<Domain>ApiService`，文件为 `lib/services/mock_api/mock_<domain>_api_service.dart`。
- 已确认 response shape 时复用 `lib/models/`；未确认结构放入 `lib/services/mock_api/models/`。
- fixture、seed 和演示实体只保存在 Mock 实现或 mock-only model 中，不放在 Widget、ViewModel、`product_preview` 或正式 model 的顶层常量里。
- Mock 只返回接口数据，可按需求模拟延迟、空结果、错误或状态分支，不处理 UI 行为。

## ApiService 组装与注入

- 在 ApiService 默认 factory 中集中选择 mock 或非 mock 实现，所有 domain 字段保持 final。
- mock 和真实阶段共享同一个 domain contract 与 `ApiService.<domain>` 入口。
- 非 mock 分支对未确认 domain 使用 Unimplemented；已确认 domain 继续使用现有 Dio 实现。
- ViewModel 依赖 contract；AppPage provider 从 `AppContainer.shared.apiService.<domain>` 取得并构造注入。
- 生产调用代码不直接 import `services/mock_api/`；测试可以直接构造 Mock 验证 contract 行为。
- 不在 Widget 或 ViewModel 中判断 mock/real，也不为预览改变默认环境。

## Product Preview

- Product Preview 与正式页面遵守同一数据来源规则，业务演示数据从 Mock API 获取。
- 预览 ViewModel 只保存当前步骤、tab、展开、筛选、选中项和输入等交互状态。
- 套餐、价格、额度、机构、消息、记录等由注入的 domain contract 提供；不要为了预览复制一份局部 fixture。
- AppPage provider 与正式页面一样从 `AppContainer.shared.apiService.<domain>` 注入依赖，registry 不创建 service 或判断环境。

## 存量迁移检查

- 为每组业务 fixture 找到所属 domain，优先扩展已有 contract，避免创建页面专用 service。
- 将演示数据移入 Mock 实现或 mock-only model 后，删除原位置的数据副本，避免两套来源漂移。
- 保留 UI 状态和展示资源，不为满足目录规则把所有常量机械迁入 API。
- 验证 Mock 环境的正常、空数据、错误或延迟场景中实际需要的部分，并验证非 mock 的未实现分支明确失败。
- 检查正式和预览调用方只依赖 contract，环境选择只存在于 ApiService 组装层。

## 协议确认后的边界

- 后台确认后停止扩展临时 contract 和 mock-only model，列出路径、字段、解析和错误处理的对齐需求。
- 保持 `ApiService.<domain>` 和调用方依赖的 contract 稳定，避免因临时实现重写调用方。
- 不在本工作流中迁移正式 model、创建 Dio 实现或替换非 mock 分支的 Unimplemented。
