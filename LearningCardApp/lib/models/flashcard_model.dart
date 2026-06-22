class Flashcard {
  final int id;
  final int setId;
  final int userId;
  final String front;
  final String back;
  final String example;
  final String? imageUrl;

  const Flashcard({
    required this.id,
    required this.setId,
    required this.userId,
    required this.front,
    required this.back,
    required this.example,
    this.imageUrl,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] ?? 0,
      setId: json['set_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      example: json['example'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}