import '../models/search_result_model.dart';
import 'api_service.dart';

class SearchService {
  final ApiService _api = ApiService();

  Future<SearchResults> search(String query) async {
    await _api.loadSavedToken();
    final response = await _api.dio.get(
      '/search',
      queryParameters: {'q': query},
    );
    return SearchResults.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }
}
