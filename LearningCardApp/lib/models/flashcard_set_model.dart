class FlashcardSet {
  final String id;
  final String title;
  final String description;
  final String color;

  FlashcardSet({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
  });

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#6C63FF',
    );
  }
}