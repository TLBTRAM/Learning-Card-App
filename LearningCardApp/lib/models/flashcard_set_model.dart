class FlashcardSet {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String color;
  final int cardCount;

  const FlashcardSet({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.color,
    this.cardCount = 0,
  });

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#7C6CFF',
      cardCount: json['card_count'] ?? 0,
    );
  }
}