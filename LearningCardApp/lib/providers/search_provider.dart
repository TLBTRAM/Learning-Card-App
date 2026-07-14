import 'package:flutter/material.dart';

import '../models/search_result_model.dart';
import '../services/search_service.dart';

class SearchProvider extends ChangeNotifier {
  final SearchService _service = SearchService();

  SearchResults results = const SearchResults();
  bool isLoading = false;
  String? errorMessage;
  String activeQuery = '';
  int _requestId = 0;

  Future<void> search(String query) async {
    final normalized = query.trim();
    activeQuery = normalized;
    final requestId = ++_requestId;
    if (normalized.isEmpty) {
      results = const SearchResults();
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final next = await _service.search(normalized);
      if (requestId != _requestId) return;
      results = next;
    } catch (error) {
      if (requestId != _requestId) return;
      errorMessage = error.toString();
    } finally {
      if (requestId == _requestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    _requestId += 1;
    results = const SearchResults();
    activeQuery = '';
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}
