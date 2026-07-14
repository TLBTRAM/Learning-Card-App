import 'package:flutter/material.dart';

import '../models/review_dashboard_model.dart';
import '../services/dashboard_service.dart';

class ReviewProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  ReviewDashboardData data = const ReviewDashboardData();
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadReview() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.getReviewDashboard();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    data = const ReviewDashboardData();
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}
