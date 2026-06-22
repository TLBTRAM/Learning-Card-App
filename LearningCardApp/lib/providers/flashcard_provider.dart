import 'package:flutter/material.dart';
import '../models/flashcard_set_model.dart';
import '../services/flashcard_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardService flashcardService = FlashcardService();

  List<FlashcardSet> sets = [];
  bool isLoading = false;

  Future<void> loadSets() async {
    isLoading = true;
    notifyListeners();

    try {
      sets = await flashcardService.getSets();
    } catch (e) {
      debugPrint('Load sets error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> addSet(String title, String description) async {
    await flashcardService.createSet(
      title: title,
      description: description,
    );
    await loadSets();
  }
}