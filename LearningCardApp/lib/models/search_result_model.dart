import 'flashcard_model.dart';
import 'flashcard_set_model.dart';
import 'note_model.dart';

class CardSearchResult {
  final Flashcard card;
  final FlashcardSet set;

  const CardSearchResult({required this.card, required this.set});

  factory CardSearchResult.fromJson(Map<String, dynamic> json) {
    return CardSearchResult(
      card: Flashcard.fromJson(json),
      set: FlashcardSet.fromJson({
        'id': json['set_id'],
        'user_id': json['set_user_id'],
        'title': json['set_title'],
        'description': json['set_description'],
        'color': json['set_color'],
        'visibility': json['set_visibility'],
        'owner_name': json['owner_name'],
        'is_owner': json['is_owner'],
        'access_type': json['is_owner'] == 1 ? 'owner' : 'shared',
        'card_count': json['set_card_count'],
      }),
    );
  }
}

class SearchResults {
  final List<FlashcardSet> sets;
  final List<CardSearchResult> cards;
  final List<NoteModel> notes;

  const SearchResults({
    this.sets = const [],
    this.cards = const [],
    this.notes = const [],
  });

  bool get isEmpty => sets.isEmpty && cards.isEmpty && notes.isEmpty;
  int get totalCount => sets.length + cards.length + notes.length;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      sets: (json['sets'] as List? ?? const [])
          .map((item) => FlashcardSet.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      cards: (json['cards'] as List? ?? const [])
          .map(
            (item) =>
                CardSearchResult.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      notes: (json['notes'] as List? ?? const [])
          .map((item) => NoteModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
