import 'package:flutter/material.dart';

import '../models/flashcard_set_model.dart';
import '../services/flashcard_set_service.dart';

class FlashcardSetProvider extends ChangeNotifier {
  final FlashcardSetService _service = FlashcardSetService();

  List<FlashcardSet> sets = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadSets() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      sets = await _service.getSets();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSet({required String title, required String description, String color = '#7C6CFF'}) async {
    await _service.createSet(title: title, description: description, color: color);
    await loadSets();
  }

  Future<void> updateSet({required int id, required String title, required String description, String color = '#7C6CFF'}) async {
    await _service.updateSet(id: id, title: title, description: description, color: color);
    await loadSets();
  }

  Future<void> deleteSet(int id) async {
    await _service.deleteSet(id);
    await loadSets();
  }
}