import '../core/utils/json_value.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int dailyGoal;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.dailyGoal = 20,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      dailyGoal: JsonValue.asInt(json['daily_goal'], fallback: 20),
    );
  }
}
