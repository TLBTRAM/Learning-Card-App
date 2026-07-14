class ChatMessageModel {
  final String role;
  final String message;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.role,
    required this.message,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
}
