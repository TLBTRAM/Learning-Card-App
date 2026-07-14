import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final token = response.data['token'] as String;
      await _api.saveToken(token);
      return {'token': token, 'user': UserModel.fromJson(response.data['data'])};
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Đăng nhập thất bại.');
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
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

      if (response.data['token'] != null) {
        await _api.saveToken(response.data['token'] as String);
      }

      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Đăng ký thất bại.');
      }
      throw Exception('Có lỗi xảy ra trong quá trình kết nối, vui lòng thử lại sau.');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      await _api.loadSavedToken();
      final response = await _api.dio.get('/auth/profile');
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Không thể tải thông tin hồ sơ.');
      }
      throw Exception('Lỗi xác thực người dùng.');
    }
  }

  Future<void> logout() => _api.clearToken();
}