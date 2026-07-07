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

  const Flashcard({
    required this.id, required this.setId, required this.userId,
    required this.front, required this.back, required this.example,
    required this.optionA, required this.optionB, required this.optionC, required this.optionD,
    required this.correctOption,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] ?? 0,
      setId: json['set_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      example: json['example'] ?? '',
      optionA: json['option_a'] ?? '',
      optionB: json['option_b'] ?? '',
      optionC: json['option_c'] ?? '',
      optionD: json['option_d'] ?? '',
      correctOption: json['correct_option'] ?? 'A',
    );
  }
}