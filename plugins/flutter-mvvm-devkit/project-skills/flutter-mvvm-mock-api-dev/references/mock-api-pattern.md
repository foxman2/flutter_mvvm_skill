# Mock API 与 AppContainer 模式

## 先读项目实现

优先读取：

- `lib/services/api/api_service.dart`
- 最接近的 domain contract；模板示例存在时可参考 `user_api_service.dart`
- `lib/services/mock_api/` 下的对应实现；模板示例存在时可参考 `mock_user_api_service.dart`
- `lib/services/mock_api/models/`、调用方和测试

示例 domain 只用于理解模式，不要因为参考文件而创建无关业务代码。

## Contract 与占位实现

- 在 `lib/services/api/<domain>_api_service.dart` 定义调用方可依赖的 `<Domain>ApiService`。
- 协议未确认的非 mock 分支使用 `Unimplemented<Domain>ApiService` fail-fast。
- Unimplemented 实现不持有 Dio，也不使用 `Dio<Domain>ApiService` 名称。
- contract 的未确认部分标记待审核；不要编造 URL、字段或响应解析。

## Mock 实现与 model

- Mock 类命名为 `Mock<Domain>ApiService`，文件为 `lib/services/mock_api/mock_<domain>_api_service.dart`。
- 已确认 response shape 时复用 `lib/models/`；未确认结构放入 `lib/services/mock_api/models/`。
- Mock 只返回接口数据，可按需求模拟延迟、错误或状态分支，不处理 UI 行为。

## ApiService 组装与注入

- 在 ApiService 默认 factory 中集中选择 mock 或非 mock 实现，所有 domain 字段保持 final。
- mock 和真实阶段共享同一个 domain contract 与 `ApiService.<domain>` 入口。
- 非 mock 分支对未确认 domain 使用 Unimplemented；已确认 domain 继续使用现有 Dio 实现。
- ViewModel 依赖 contract；AppPage provider 从 `AppContainer.shared.apiService.<domain>` 取得并构造注入。
- 不在 Widget 或 ViewModel 中判断 mock/real，也不为预览改变默认环境。

## 协议确认后的边界

- 后台确认后停止扩展临时 contract 和 mock-only model，列出路径、字段、解析和错误处理的对齐需求。
- 保持 `ApiService.<domain>` 和调用方依赖的 contract 稳定，避免因临时实现重写调用方。
- 不在本工作流中迁移正式 model、创建 Dio 实现或替换非 mock 分支的 Unimplemented。
