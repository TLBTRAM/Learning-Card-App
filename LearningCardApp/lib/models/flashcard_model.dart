import '../core/utils/json_value.dart';

class Flashcard {
  final int id;
  final int setId;
  final int userId;
  final String front;
  final String back; // Giữ lại để làm đáp án đúng
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // Lưu giá trị: 'A', 'B', 'C', hoặc 'D'
  final String example;
  final String creatorName;
  final String? reviewRating;
  final DateTime? nextReviewAt;

  const Flashcard({
    required this.id,
    required this.setId,
    required this.userId,
    required this.front,
    required this.back,
    required this.example,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.creatorName = '',
    this.reviewRating,
    this.nextReviewAt,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: JsonValue.asInt(json['id']),
      setId: JsonValue.asInt(json['set_id']),
      userId: JsonValue.asInt(json['user_id']),
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      example: json['example'] ?? '',
      optionA: json['option_a'] ?? '',
      optionB: json['option_b'] ?? '',
      optionC: json['option_c'] ?? '',
      optionD: json['option_d'] ?? '',
      correctOption: json['correct_option'] ?? 'A',
      creatorName: json['creator_name']?.toString() ?? '',
      reviewRating:
          json['review_rating']?.toString() ?? json['rating']?.toString(),
      nextReviewAt: DateTime.tryParse(json['next_review_at']?.toString() ?? ''),
    );
  }
}
