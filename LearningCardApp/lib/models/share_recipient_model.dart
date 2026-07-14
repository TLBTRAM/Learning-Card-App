import '../core/utils/json_value.dart';

class ShareRecipient {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String permission;

  const ShareRecipient({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.permission = 'viewer',
  });

  factory ShareRecipient.fromJson(Map<String, dynamic> json) {
    return ShareRecipient(
      id: JsonValue.asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      permission: json['permission']?.toString() ?? 'viewer',
    );
  }
}
