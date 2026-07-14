import 'package:dio/dio.dart';
import 'api_service.dart';

class AiService {
  final ApiService _api = ApiService();

  Future<String> sendMessage(String message) async {
    try {
      final response = await _api.dio.post('/ai/chat', data: {'message': message});
      if (response.data != null && response.data['success'] == true) {
        return response.data['data']['answer'] ?? '';
      }
      throw Exception(response.data['message'] ?? 'Lỗi không xác định từ máy chủ.');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Trợ lý AI đang bận.');
      }
      throw Exception('Không thể kết nối đến máy chủ AI.');
    }
  }

  Future<String> explain(String topic) async {
    try {
      final response = await _api.dio.post('/ai/explain', data: {'topic': topic});
      if (response.data != null && response.data['success'] == true) {
        return response.data['data']['explanation'] ?? '';
      }
      throw Exception(response.data['message'] ?? 'Lỗi không thể giải nghĩa chủ đề.');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Yêu cầu thất bại.');
      }
      throw Exception('Mất kết nối máy chủ.');
    }
  }

  Future<String> summarizeNotes(String notes) async {
    try {
      final response = await _api.dio.post('/ai/summarize-notes', data: {'notes': notes});
      if (response.data != null && response.data['success'] == true) {
        return response.data['data']['summary'] ?? '';
      }
      throw Exception(response.data['message'] ?? 'Lỗi không thể tóm tắt.');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Yêu cầu thất bại.');
      }
      throw Exception('Mất kết nối máy chủ.');
    }
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(String text) async {
    try {
      final response = await _api.dio.post('/ai/generate-flashcards', data: {'text': text});
      if (response.data != null && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Lỗi không thể sinh thẻ ghi nhớ.');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Yêu cầu thất bại.');
      }
      throw Exception('Mất kết nối máy chủ.');
    }
  }
}