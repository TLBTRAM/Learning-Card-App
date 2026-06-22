class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}