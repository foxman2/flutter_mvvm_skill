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

每个新增 model 至少覆盖：

- 必填字段能解析。
- 可空字段、缺失字段或空列表按约定处理。
- 有请求 model 时，`toJson()` 输出符合接口字段名。

## Mock-only model

后台未确认的临时结构不要放在 `lib/models/`。先放到 `lib/services/mock_api/models/`，并使用 `$flutter-mvvm-mock-api-dev` 的迁移约定；后台确认后再合并到正式 model。
