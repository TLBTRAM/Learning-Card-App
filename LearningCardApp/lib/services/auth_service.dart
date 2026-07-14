import 'package:dio/dio.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    await _api.saveToken(token);
    return {'token': token, 'user': UserModel.fromJson(response.data['data'])};
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      // Nếu Backend trả về 409 Conflict, Exception này sẽ kích hoạt
      if (e.response?.statusCode == 400 || e.response?.statusCode == 409) {
        throw Exception(
          'Email hoặc Họ tên đã tồn tại, vui lòng chọn thông tin khác.',
        );
      }
      throw Exception('Có lỗi xảy ra, vui lòng thử lại sau.');
    }
  }

  Future<UserModel> getProfile() async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/auth/profile');
    return UserModel.fromJson(response.data['data']);
  }

  Future<void> logout() => _api.clearToken();
}
