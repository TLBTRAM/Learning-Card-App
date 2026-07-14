import 'package:flutter/material.dart';

import '../models/flashcard_set_model.dart';
import '../models/share_recipient_model.dart';
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

  Future<FlashcardSet> createSet({
    required String title,
    required String description,
    String color = '#7C6CFF',
  }) async {
    final created = await _service.createSet(
      title: title,
      description: description,
      color: color,
    );
    await loadSets();
    return created;
  }

  Future<void> updateSet({
    required int id,
    required String title,
    required String description,
    String color = '#7C6CFF',
  }) async {
    await _service.updateSet(
      id: id,
      title: title,
      description: description,
      color: color,
    );
    await loadSets();
  }

  Future<void> deleteSet(int id) async {
    await _service.deleteSet(id);
    await loadSets();
  }

  Future<List<ShareRecipient>> getShares(int setId) =>
      _service.getShares(setId);

  Future<void> shareWithEmail(int setId, String email) async {
    await _service.shareWithEmail(setId, email);
    await loadSets();
  }

  Future<void> revokeShare(int setId, int userId) async {
    await _service.revokeShare(setId, userId);
    await loadSets();
  }

  Future<void> updateVisibility(int setId, String visibility) async {
    await _service.updateVisibility(setId, visibility);
    await loadSets();
  }

  void clear() {
    sets = [];
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}
