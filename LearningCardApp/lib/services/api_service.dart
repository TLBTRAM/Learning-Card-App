import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}