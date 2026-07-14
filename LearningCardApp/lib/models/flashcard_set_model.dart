import '../core/utils/json_value.dart';

class FlashcardSet {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String color;
  final int cardCount;
  final String ownerName;
  final bool isOwner;
  final String accessType;
  final String visibility;
  final int shareCount;
  final int progressPercent;
  final int progressLearnedCards;
  final int progressTotalCards;

  const FlashcardSet({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.color,
    this.cardCount = 0,
    this.ownerName = '',
    this.isOwner = true,
    this.accessType = 'owner',
    this.visibility = 'private',
    this.shareCount = 0,
    this.progressPercent = 0,
    this.progressLearnedCards = 0,
    this.progressTotalCards = 0,
  });

  bool get isShared => accessType == 'shared';
  bool get isPublic => visibility == 'public';

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: JsonValue.asInt(json['id']),
      userId: JsonValue.asInt(json['user_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      color: json['color']?.toString() ?? '#17233C',
      cardCount: JsonValue.asInt(json['card_count']),
      ownerName: json['owner_name']?.toString() ?? '',
      isOwner: json['is_owner'] == null
          ? true
          : (json['is_owner'] == true || json['is_owner'] == 1),
      accessType: json['access_type']?.toString() ?? 'owner',
      visibility: json['visibility']?.toString() ?? 'private',
      shareCount: JsonValue.asInt(json['share_count']),
      progressPercent: JsonValue.asInt(json['progress_percent']),
      progressLearnedCards: JsonValue.asInt(json['progress_learned_cards']),
      progressTotalCards: JsonValue.asInt(json['progress_total_cards']),
    );
  }
}
