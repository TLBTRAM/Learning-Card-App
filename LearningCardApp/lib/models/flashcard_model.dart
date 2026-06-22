class Flashcard {
  final String id;
  final String setId;
  final String front;
  final String back;
  final String example;

  Flashcard({
    required this.id,
    required this.setId,
    required this.front,
    required this.back,
    required this.example,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['_id'] ?? '',
      setId: json['setId'] ?? '',
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      example: json['example'] ?? '',
    );
  }
}