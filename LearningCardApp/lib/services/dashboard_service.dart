import '../models/dashboard_model.dart';
import '../models/review_dashboard_model.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _api = ApiService();

  Future<DashboardData> getDashboard() async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/dashboard');
    return DashboardData.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<ReviewDashboardData> getReviewDashboard() async {
    await _api.loadSavedToken();
    final response = await _api.dio.get('/dashboard/review');
    return ReviewDashboardData.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }
}
