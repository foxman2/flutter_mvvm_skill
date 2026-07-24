# Model 解析模式

## 命名

- 响应 model：`UserProfile`、`OrderSummary`。
- 请求 model：`UpdateProfileRequest`、`CreateOrderRequest`。
- 文件使用 snake_case，类使用 PascalCase。

## 推荐方案：json_serializable

正式 request/response model 推荐使用 `json_serializable`。采用时确保项目包含运行时
依赖 `json_annotation`，以及开发依赖 `json_serializable` 和 `build_runner`。项目已有
稳定序列化方案时沿用现有约定，不并行引入另一套方案。

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  const UserProfile({required this.id, required this.name});

  final String id;
  final String name;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
```

采用 `json_serializable` 后，在新增或修改 JSON model 时生成代码：

```bash
dart run build_runner build --delete-conflicting-outputs
```

采用该方案时保留生成的 `.g.dart` 文件，但不要手动修改。

## 缺失值和嵌套列表

使用 `JsonKey` 明确缺失字段的默认值；包含嵌套 model 的响应使用
`explicitToJson: true`：

```dart
import 'package:json_annotation/json_annotation.dart';

import 'user_profile.dart';

part 'user_list_response.g.dart';

@JsonSerializable(explicitToJson: true)
class UserListResponse {
  const UserListResponse({this.users = const []});

  @JsonKey(defaultValue: <UserProfile>[])
  final List<UserProfile> users;

  factory UserListResponse.fromJson(Map<String, dynamic> json) =>
      _$UserListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserListResponseToJson(this);
}
```

字段名不一致、日期格式或其他协议转换使用 `JsonKey` 的 `name`、`fromJson`、
`toJson`，或定义可复用的 `JsonConverter`，不要把字段解析重新写回 factory。

## 测试

不要为每个新增 model 固定生成测试。只有 model 包含以下行为时补针对性测试：

- `JsonKey` 默认值、缺失字段或可空兼容逻辑。
- 嵌套集合、自定义 `JsonConverter` 或非直映射字段。
- 复杂序列化约定或已发生过的解析回归。

`json_serializable` 生成的简单必填字段映射由代码生成、analyzer 和代表性 API
contract 覆盖，不单独为每个 DTO 创建测试文件。

## Mock-only model

后台未确认的临时结构不要放在 `lib/models/`。先放到 `lib/services/mock_api/models/`，并使用 `$flutter-mvvm-mock-api-dev` 的迁移约定；后台确认后再合并到正式 model。
