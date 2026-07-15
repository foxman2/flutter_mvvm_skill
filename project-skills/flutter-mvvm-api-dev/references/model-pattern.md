# Model 解析模式

## 目录和命名

```text
lib/models/user/
├── user_profile.dart
└── update_profile_request.dart
```

- 响应 model：`UserProfile`、`OrderSummary`。
- 请求 model：`UpdateProfileRequest`、`CreateOrderRequest`。
- 文件使用 snake_case，类使用 PascalCase。

## 普通 model

暂不引入 freezed/codegen，默认手写：

```dart
class UserProfile {
  const UserProfile({required this.id, required this.name});

  final String id;
  final String name;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
```

## 可空和列表

对服务端可能缺失的字段做明确选择：

```dart
class UserListResponse {
  const UserListResponse({required this.users});

  final List<UserProfile> users;

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'];
    return UserListResponse(
      users: rawUsers is List
          ? rawUsers
              .whereType<Map<String, dynamic>>()
              .map(UserProfile.fromJson)
              .toList()
          : const [],
    );
  }
}
```

## 测试

不要为每个新增 model 固定生成测试。只有 model 包含以下行为时补针对性测试：

- 默认值、缺失字段或可空兼容逻辑。
- 嵌套集合过滤、类型转换或非直映射字段。
- 复杂 `toJson()` 约定或已发生过的解析回归。

简单必填字段的直接赋值由编译器、analyzer 和代表性 API contract 覆盖，不单独为每个 DTO 创建测试文件。

## Mock-only model

后台未确认的临时结构不要放在 `lib/models/`。先放到 `lib/services/mock_api/models/`，并使用 `$flutter-mvvm-mock-api-dev` 的迁移约定；后台确认后再合并到正式 model。
