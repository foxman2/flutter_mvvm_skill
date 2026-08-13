import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

/// 用户资料接口模型，JSON 转换代码由 json_serializable 生成。
@JsonSerializable()
class UserProfile {
  const UserProfile({required this.id, required this.name});

  final String id;
  final String name;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
