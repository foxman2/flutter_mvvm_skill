# Model 与 JSON 解析

## 先读什么

先读同一业务的已有 model。模板的 `lib/models/user/user_profile.dart` 还在时可以参考。沿用现有解析方案，不同时引入另一套。

## 命名和分工

- 响应类型用业务名，例如 `UserProfile`、`OrderSummary`。
- 请求类型用动作名，例如 `UpdateProfileRequest`。
- 文件名用 snake_case，类名用 PascalCase。
- JSON 字段映射只放在 model，不散落到 API、VM 或 Widget。
- DTO 表达后台字段；领域 Model 管理自身业务规则，不发请求、不查全局依赖。两者含义一致时可以共用类型，不必另建 Entity。
- 确实需要转换时，由 Repository 或纯映射函数完成。不要为一次字段改名引入映射框架。分工见[文件职责](../../shared-references/architecture-responsibilities.md)。

## json_serializable

正式请求和响应 model 推荐用 `json_serializable`：

- 添加 `@JsonSerializable()` 和 `part`，`fromJson/toJson` 调用生成函数。
- 运行依赖用 `json_annotation`，开发依赖用 `json_serializable` 和 `build_runner`。
- 字段改名、默认值和自定义转换用 `JsonKey` 或 `JsonConverter`。
- 嵌套 model 需要序列化时，用 `explicitToJson: true`。
- 改 model 后运行下面的命令。保留生成的 `.g.dart`，不要手改。

```bash
dart run build_runner build
```

项目已有稳定手写解析时可以继续用，但解析仍放在 model 内。

协议没确认的临时结构放在 `lib/services/mock_api/models/`，不要提前放进 `lib/models/`。
