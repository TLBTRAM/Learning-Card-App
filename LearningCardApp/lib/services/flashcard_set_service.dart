import '../models/flashcard_set_model.dart';
import '../models/share_recipient_model.dart';
import 'api_service.dart';

class FlashcardSetService {
  final ApiService _api = ApiService();

  Future<List<FlashcardSet>> getSets() async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/sets');
    final data = response.data['data'] as List<dynamic>;
    return data.map((item) => FlashcardSet.fromJson(item)).toList();
  }

  Future<FlashcardSet> createSet({
    required String title,
    required String description,
    required String color,
  }) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post(
      '/sets',
      data: {'title': title, 'description': description, 'color': color},
    );
    return FlashcardSet.fromJson(response.data['data']);
  }

  Future<void> updateSet({
    required int id,
    required String title,
    required String description,
    required String color,
  }) async {
    await _api.loadSavedToken();
    await _api.dio.put(
      '/sets/$id',
      data: {'title': title, 'description': description, 'color': color},
    );
  }

  Future<void> deleteSet(int id) async {
    await _api.loadSavedToken();
    await _api.dio.delete('/sets/$id');
  }

  Future<List<ShareRecipient>> getShares(int setId) async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/sets/$setId/shares');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((item) => ShareRecipient.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ShareRecipient> shareWithEmail(int setId, String email) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post(
      '/sets/$setId/share',
      data: {'email': email},
    );
    return ShareRecipient.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<void> revokeShare(int setId, int userId) async {
    await _api.loadSavedToken();
    await _api.dio.delete('/sets/$setId/shares/$userId');
  }

  Future<void> updateVisibility(int setId, String visibility) async {
    await _api.loadSavedToken();
    await _api.dio.put(
      '/sets/$setId/visibility',
      data: {'visibility': visibility},
    );
  }
}
