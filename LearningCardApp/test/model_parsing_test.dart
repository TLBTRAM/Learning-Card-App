import 'package:flutter_test/flutter_test.dart';
import 'package:learningcardapp/models/dashboard_model.dart';
import 'package:learningcardapp/models/flashcard_set_model.dart';

void main() {
  test('flashcard set accepts numeric values encoded as strings', () {
    final set = FlashcardSet.fromJson({
      'id': '12',
      'user_id': '3',
      'title': 'Demo',
      'description': '',
      'color': '#17233C',
      'card_count': '6',
      'share_count': '1',
      'progress_percent': '67',
      'progress_learned_cards': '4',
      'progress_total_cards': '6',
    });

    expect(set.id, 12);
    expect(set.cardCount, 6);
    expect(set.progressPercent, 67);
  });

  test('dashboard accepts MySQL aggregate values encoded as strings', () {
    final dashboard = DashboardData.fromJson({
      'daily_goal': '18',
      'owned_sets': '3',
      'today': {
        'sessions': '2',
        'learned_cards': '7',
        'correct_answers': '9',
        'wrong_answers': '2',
      },
      'weekly_activity': [
        {'date': '2026-07-14', 'learned_cards': '7'},
      ],
      'recent_sets': [
        {
          'id': 1,
          'user_id': 1,
          'title': 'Demo',
          'description': '',
          'color': '#17233C',
          'progress_percent': '50',
        },
      ],
    });

    expect(dashboard.dailyGoal, 18);
    expect(dashboard.today.sessions, 2);
    expect(dashboard.weeklyActivity.single.learnedCards, 7);
    expect(dashboard.recentSets.single.progressPercent, 50);
  });
}
