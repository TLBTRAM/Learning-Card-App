import 'api_service.dart';

class AiService {
  final ApiService _api = ApiService();

  Future<String> sendMessage(String message) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post(
      '/ai/chat',
      data: {'message': message},
    );
    return response.data['data']['answer'] ?? '';
  }

  Future<String> explain(String topic) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post('/ai/explain', data: {'topic': topic});
    return response.data['data']['explanation'] ?? '';
  }

  Future<String> summarizeNotes(String notes) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post(
      '/ai/summarize-notes',
      data: {'notes': notes},
    );
    return response.data['data']['summary'] ?? '';
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(String text) async {
    await _api.loadSavedToken();
    final response = await _api.dio.post(
      '/ai/generate-flashcards',
      data: {'text': text},
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
