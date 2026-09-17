# Mock API 实现与数据迁移

## 哪些是演示业务数据

模拟后台或业务结果、会影响用户理解产品能力的数据，都属于演示业务数据，例如：

- 用户、账号、订阅和额度
- 任务、消息、请求状态和 AI 结果
- 机构、匹配度、地址、电话、录音信息和转写
- 套餐、价格、权益、续订日期和可购买项
- 后台配置的目录、列表、详情和业务状态

l10n、主题、图标、静态资源路径，以及 tab、步骤、展开、输入、筛选、选中、loading 和纯展示枚举，可以留在展示层。

一个值既参与业务展示又可能由后台配置时，按业务演示数据处理。不要只看变量名是否带 mock、fixture 或 demo。

## 先读什么

- `lib/services/api/api_service.dart` 和相关业务接口
- `lib/services/mock_api/` 的对应实现
- `lib/services/mock_api/models/`、调用方和测试
- 涉及预览时，再读 Page、VM、AppPage 和 registry

模板的 `user_api_service.dart` 和 `mock_user_api_service.dart` 还在时可以参考，不要因此创建无关业务。

迁移旧数据时，搜索 Page、VM、Screen、预览、model 和测试里的业务对象、价格、账号、消息、结果和记录。按[文件职责](../../shared-references/architecture-responsibilities.md)区分编造的数据、请求结果和草稿。调用方保存请求结果本身没有问题。

## 接口和未实现分支

- 在 `lib/services/api/<domain>_api_service.dart` 定义 `<Domain>ApiService`。
- 方法表达业务动作，不按页面各建一套接口，不暴露未确认的 HTTP 路径、字段或响应外层格式。
- 未确认部分标记为待审核。
- 非 mock 分支用 `Unimplemented<Domain>ApiService` 明确报未实现。它不持有 Dio，也不叫 `Dio<Domain>ApiService`。

## Mock 和 model

- 类名用 `Mock<Domain>ApiService`，文件为 `lib/services/mock_api/mock_<domain>_api_service.dart`。
- 响应结构已确认就复用 `lib/models/`；没确认就放在 `lib/services/mock_api/models/`。
- fixture、seed 和演示实体只放在 Mock 实现或临时 model，不放在 Widget、VM、预览或正式 model 顶层常量中。
- 按需求模拟延迟、空数据、错误和状态变化。可以用内存记录保持创建、更新和查询一致，不处理客户端业务流程或 UI。

## 组装和注入

- ApiService 默认 factory 按环境选择实现，业务模块字段保持 final。
- Mock 和真实实现使用同一业务接口和 `ApiService.<domain>` 入口。
- 非 mock 环境：未确认接口用 Unimplemented；已确认接口保留已有 Dio 实现。
- AppPage provider 从 `AppContainer.shared.apiService.<domain>` 取得接口并注入 VM。
- 数据已有 Repository 管理时，把接口注入 Repository，再把 Repository 注入 VM，不绕过数据入口。
- 正式调用方不 import 具体 Mock。测试可以直接构造 Mock 来验证接口行为。
- Widget、VM 不判断 mock/real，不为预览修改默认环境。

## Product Preview

- 预览的套餐、价格、额度、机构、消息和记录也从 Mock API 获取，不保存另一份局部演示数据。
- 预览 VM 可以保存请求结果、步骤、tab、筛选、输入和草稿，不编造业务数据，不另建共享缓存。
- AppPage provider 注入业务接口或已有 Repository。registry 不创建 service，不判断环境。

## 迁移检查

- 每组演示数据归到对应业务接口，优先扩展已有接口，不建页面专用 service。
- 数据移到 Mock 或临时 model 后，删除原来的副本。
- 保留 UI 状态和展示资源，不把所有常量都搬进 API。
- 验证当前需要的正常、空数据、错误或延迟场景；确认非 mock 的未实现分支明确失败。
- 正式和预览调用方只用注入的接口或 Repository，环境选择只在 ApiService 组装层。

## 协议确认后

- 停止扩展临时接口和 model，列出路径、字段、解析和错误处理需要对齐的地方。
- 按正式协议更新接口和调用方，不为保留临时结构加兼容层。
- 正式 model 迁移、Dio 实现和替换 Unimplemented，交给正式 API 开发 skill。
