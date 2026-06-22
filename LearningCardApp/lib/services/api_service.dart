import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
    dio.options.headers.remove('Authorization');
  }
}