import 'package:dio/dio.dart';
import 'api_service.dart';

class AiService {
  final ApiService _api = ApiService();

  Future<String> sendMessage(String message, String sessionId) async {
    try {
      final response = await _api.dio.post('/ai/chat', data: {
        'message': message,
        'sessionId': sessionId,
      });
      if (response.data != null && response.data['success'] == true) {
        return response.data['data']['answer'] ?? '';
      }
      throw Exception(response.data['message'] ?? 'Lỗi hệ thống không xác định.');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Kết nối tới trợ lý thất bại.');
      }
      throw Exception('Vui lòng kiểm tra lại đường truyền mạng.');
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final response = await _api.dio.get('/ai/sessions');
      if (response.data != null && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
    try {
      final response = await _api.dio.get('/ai/sessions/$sessionId');
      if (response.data != null && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _api.dio.delete('/ai/sessions/$sessionId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Không thể xóa hội thoại.');
    }
  }
}