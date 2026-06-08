import 'flashcard.dart';

class StudySet {
  final String id;
  final String title;
  final String description;
  final List<Flashcard> cards;
  final double progress;

  StudySet({
    required this.id,
    required this.title,
    required this.description,
    required this.cards,
    required this.progress,
  });
}