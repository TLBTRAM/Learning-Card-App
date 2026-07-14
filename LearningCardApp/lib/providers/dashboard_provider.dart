import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  DashboardData data = const DashboardData();
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.getDashboard();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    data = const DashboardData();
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}
