import '../core/utils/json_value.dart';
import 'flashcard_set_model.dart';

class DailyStudyStats {
  final int sessions;
  final int learnedCards;
  final int correctAnswers;
  final int wrongAnswers;

  const DailyStudyStats({
    this.sessions = 0,
    this.learnedCards = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
  });

  factory DailyStudyStats.fromJson(Map<String, dynamic> json) {
    return DailyStudyStats(
      sessions: JsonValue.asInt(json['sessions']),
      learnedCards: JsonValue.asInt(json['learned_cards']),
      correctAnswers: JsonValue.asInt(json['correct_answers']),
      wrongAnswers: JsonValue.asInt(json['wrong_answers']),
    );
  }
}

class WeeklyStudyPoint {
  final DateTime date;
  final int learnedCards;

  const WeeklyStudyPoint({required this.date, required this.learnedCards});

  factory WeeklyStudyPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyStudyPoint(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      learnedCards: JsonValue.asInt(json['learned_cards']),
    );
  }
}

class DashboardData {
  final int dailyGoal;
  final int ownedSets;
  final int sharedSets;
  final int totalSets;
  final int ownedNotes;
  final int sharedNotes;
  final int learnedCards;
  final int dueCards;
  final int studyStreak;
  final DailyStudyStats today;
  final List<WeeklyStudyPoint> weeklyActivity;
  final List<FlashcardSet> recentSets;

  const DashboardData({
    this.dailyGoal = 20,
    this.ownedSets = 0,
    this.sharedSets = 0,
    this.totalSets = 0,
    this.ownedNotes = 0,
    this.sharedNotes = 0,
    this.learnedCards = 0,
    this.dueCards = 0,
    this.studyStreak = 0,
    this.today = const DailyStudyStats(),
    this.weeklyActivity = const [],
    this.recentSets = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      dailyGoal: JsonValue.asInt(json['daily_goal'], fallback: 20),
      ownedSets: JsonValue.asInt(json['owned_sets']),
      sharedSets: JsonValue.asInt(json['shared_sets']),
      totalSets: JsonValue.asInt(json['total_sets']),
      ownedNotes: JsonValue.asInt(json['owned_notes']),
      sharedNotes: JsonValue.asInt(json['shared_notes']),
      learnedCards: JsonValue.asInt(json['learned_cards']),
      dueCards: JsonValue.asInt(json['due_cards']),
      studyStreak: JsonValue.asInt(json['study_streak']),
      today: DailyStudyStats.fromJson(
        Map<String, dynamic>.from(json['today'] as Map? ?? const {}),
      ),
      weeklyActivity: (json['weekly_activity'] as List? ?? const [])
          .map(
            (item) =>
                WeeklyStudyPoint.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      recentSets: (json['recent_sets'] as List? ?? const [])
          .map((item) => FlashcardSet.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
