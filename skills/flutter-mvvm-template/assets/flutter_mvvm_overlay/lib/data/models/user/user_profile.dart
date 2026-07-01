class UserProfile {
  const UserProfile({required this.id, required this.name});

  final String id;
  final String name;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
