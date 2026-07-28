# Model 解析模式

## 先读项目实现

优先读取同一 domain 的现有 model；模板示例存在时可参考 `lib/models/user/user_profile.dart`。沿用项目已有序列化方案，不并行引入第二套机制。

## 命名与职责

- 响应类型使用业务名，如 `UserProfile`、`OrderSummary`。
- 请求类型使用动作后缀，如 `UpdateProfileRequest`。
- 文件使用 snake_case，类使用 PascalCase。
- JSON 字段映射只放在 model 内，不散落到 API service、ViewModel 或 Widget。

## json_serializable

正式 request/response model 推荐使用 `json_serializable`：

- 添加 `@JsonSerializable()`、对应 `part`，并让 `fromJson/toJson` 委托给生成函数。
- 运行时依赖使用 `json_annotation`，开发依赖使用 `json_serializable` 和 `build_runner`。
- 新增或修改 model 后运行：

```bash
dart run build_runner build
```

- 保留生成的 `.g.dart`，不要手动修改。
- 字段改名、默认值和自定义转换使用 `JsonKey` 或 `JsonConverter`；嵌套 model 需要序列化时使用 `explicitToJson: true`。

项目已有稳定手写解析方案时可继续使用，但同样把解析限制在 model 内。

## 测试边界

只为缺失值、可空兼容、嵌套集合、自定义转换、复杂序列化或已发生的解析回归新增测试。简单必填字段的生成映射由代码生成、analyzer 和代表性 API contract 覆盖。

后台未确认的临时结构放入 `lib/services/mock_api/models/`，不要提前进入 `lib/models/`。
