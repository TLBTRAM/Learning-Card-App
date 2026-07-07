import '../models/flashcard_model.dart';
import 'api_service.dart';

class FlashcardService {
  final ApiService _api = ApiService();

  Future<List<Flashcard>> getCardsBySet(int setId) async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/cards/set/$setId');
    final data = response.data['data'] as List<dynamic>;
    return data.map((item) => Flashcard.fromJson(item)).toList();
  }

  Future<void> addCard(int setId, String front, String back) async {
    await createCard(setId: setId, front: front, back: back);
  }

  Future<void> createCard({required int setId, required String front, required String back, String example = ''}) async {
    await _api.loadSavedToken();
    await _api.dio.post('/cards', data: {
      'set_id': setId,
      'front': front,
      'back': back,
      'example': example,
    });
  }

  Future<void> updateCard({required int id, required String front, required String back, String example = ''}) async {
    await _api.loadSavedToken();
    await _api.dio.put('/cards/$id', data: {
      'front': front,
      'back': back,
      'example': example,
    });
  }

  Future<void> deleteCard(int id) async {
    await _api.loadSavedToken();
    await _api.dio.delete('/cards/$id');
  }

  Future<void> saveProgress({required int setId, required int totalCards, required int learnedCards, required int correctAnswers, required int wrongAnswers}) async {
    await _api.loadSavedToken();
    await _api.dio.post('/progress', data: {
      'set_id': setId,
      'total_cards': totalCards,
      'learned_cards': learnedCards,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
    });
  }
}