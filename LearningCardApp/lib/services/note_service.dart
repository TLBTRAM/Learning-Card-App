import 'dart:convert';

import '../models/note_model.dart';
import '../models/share_recipient_model.dart';
import 'api_service.dart';

class NoteService {
  final ApiService _api = ApiService();

  List<dynamic> _parseDrawing(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is List ? decoded : <dynamic>[];
      } catch (_) {
        return <dynamic>[];
      }
    }
    return <dynamic>[];
  }

  NoteModel _mapNote(Map<String, dynamic> json) {
    return NoteModel.fromJson({
      ...json,
      'drawing_data': _parseDrawing(json['drawing_data']),
    });
  }

  Future<List<NoteModel>> getNotes() async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/notes');
    final data = response.data['data'] as List<dynamic>;
    return data.map((item) => _mapNote(item)).toList();
  }

  Future<NoteModel> createNote({
    required String title,
    required String contentText,
    required List<dynamic> drawingData,
  }) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post(
      '/notes',
      data: {
        'title': title,
        'content_text': contentText,
        'drawing_data': drawingData,
      },
    );
    return _mapNote(response.data['data']);
  }

  Future<NoteModel> updateNote({
    required int id,
    required String title,
    required String contentText,
    required List<dynamic> drawingData,
  }) async {
    await _api.loadSavedToken();
    final response = await _api.dio.put(
      '/notes/$id',
      data: {
        'title': title,
        'content_text': contentText,
        'drawing_data': drawingData,
      },
    );
    return _mapNote(response.data['data']);
  }

  Future<void> deleteNote(int id) async {
    await _api.loadSavedToken();
    await _api.dio.delete('/notes/$id');
  }

  Future<List<ShareRecipient>> getShares(int noteId) async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/notes/$noteId/shares');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((item) => ShareRecipient.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ShareRecipient> shareWithEmail(int noteId, String email) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post(
      '/notes/$noteId/share',
      data: {'email': email},
    );
    return ShareRecipient.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<void> revokeShare(int noteId, int userId) async {
    await _api.loadSavedToken();
    await _api.dio.delete('/notes/$noteId/shares/$userId');
  }

  Future<void> updateVisibility(int noteId, String visibility) async {
    await _api.loadSavedToken();
    await _api.dio.put(
      '/notes/$noteId/visibility',
      data: {'visibility': visibility},
    );
  }
}
