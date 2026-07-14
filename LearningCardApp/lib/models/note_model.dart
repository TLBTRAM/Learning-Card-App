import 'dart:convert';

import '../core/utils/json_value.dart';

class NoteModel {
  final int id;
  final int userId;
  final String title;
  final String contentText;
  final List<dynamic> drawingData;
  final String ownerName;
  final bool isOwner;
  final String accessType;
  final String visibility;
  final int shareCount;

  const NoteModel({
    required this.id,
    required this.title,
    required this.contentText,
    required this.drawingData,
    this.userId = 0,
    this.ownerName = '',
    this.isOwner = true,
    this.accessType = 'owner',
    this.visibility = 'private',
    this.shareCount = 0,
  });

  bool get isShared => accessType == 'shared';
  bool get isPublic => visibility == 'public';

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final rawDrawing = json['drawing_data'];
    List<dynamic> drawing = const [];
    if (rawDrawing is List) {
      drawing = rawDrawing;
    } else if (rawDrawing is String && rawDrawing.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDrawing);
        if (decoded is List) drawing = decoded;
      } catch (_) {
        drawing = const [];
      }
    }
    return NoteModel(
      id: JsonValue.asInt(json['id']),
      userId: JsonValue.asInt(json['user_id']),
      title: json['title']?.toString() ?? '',
      contentText: json['content_text']?.toString() ?? '',
      drawingData: drawing,
      ownerName: json['owner_name']?.toString() ?? '',
      isOwner: json['is_owner'] == null
          ? true
          : (json['is_owner'] == true || json['is_owner'] == 1),
      accessType: json['access_type']?.toString() ?? 'owner',
      visibility: json['visibility']?.toString() ?? 'private',
      shareCount: JsonValue.asInt(json['share_count']),
    );
  }
}
