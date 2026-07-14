import '../core/utils/json_value.dart';
import 'flashcard_model.dart';
import 'dashboard_model.dart';

class ReviewCardItem {
  final Flashcard card;
  final String setTitle;
  final String ownerName;
  final String category;

  const ReviewCardItem({
    required this.card,
    required this.setTitle,
    required this.ownerName,
    required this.category,
  });

  factory ReviewCardItem.fromJson(Map<String, dynamic> json) {
    return ReviewCardItem(
      card: Flashcard.fromJson(json),
      setTitle: json['set_title']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Chưa nhớ',
    );
  }
}

class ReviewDashboardData {
  final List<ReviewCardItem> cards;
  final int dueCount;
  final int estimatedMinutes;
  final int studyStreak;
  final List<WeeklyStudyPoint> weeklyActivity;
  final Set<DateTime> studyDates;

  const ReviewDashboardData({
    this.cards = const [],
    this.dueCount = 0,
    this.estimatedMinutes = 0,
    this.studyStreak = 0,
    this.weeklyActivity = const [],
    this.studyDates = const {},
  });

  factory ReviewDashboardData.fromJson(Map<String, dynamic> json) {
    return ReviewDashboardData(
      cards: (json['cards'] as List? ?? const [])
          .map(
            (item) => ReviewCardItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      dueCount: JsonValue.asInt(json['due_count']),
      estimatedMinutes: JsonValue.asInt(json['estimated_minutes']),
      studyStreak: JsonValue.asInt(json['study_streak']),
      weeklyActivity: (json['weekly_activity'] as List? ?? const [])
          .map(
            (item) =>
                WeeklyStudyPoint.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      studyDates: (json['study_dates'] as List? ?? const [])
          .map((item) => DateTime.tryParse(item.toString()))
          .whereType<DateTime>()
          .toSet(),
    );
  }
}
