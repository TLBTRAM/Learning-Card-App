import '../models/flashcard_set_model.dart';
import 'api_service.dart';

class FlashcardService {
  final ApiService apiService = ApiService();

  Future<List<FlashcardSet>> getSets() async {
    final response = await apiService.dio.get('/sets');

    final List data = response.data;
    return data.map((item) => FlashcardSet.fromJson(item)).toList();
  }

  Future<void> createSet({
    required String title,
    required String description,
  }) async {
    await apiService.dio.post(
      '/sets',
      data: {
        'title': title,
        'description': description,
        'color': '#6C63FF',
      },
    );
  }
}