import 'package:flutter/material.dart';

import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardService _service = FlashcardService();

  List<Flashcard> cards = [];
  bool isLoading = false;
  String? errorMessage;
  int correctAnswers = 0;
  int wrongAnswers = 0;

  Future<void> loadCards(int setId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cards = await _service.getCardsBySet(setId);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCard({required int setId, required String front, required String back, String example = ''}) async {
    await _service.createCard(setId: setId, front: front, back: back, example: example);
    await loadCards(setId);
  }

  Future<void> updateCard({required int setId, required int id, required String front, required String back, String example = ''}) async {
    await _service.updateCard(id: id, front: front, back: back, example: example);
    await loadCards(setId);
  }

  Future<void> deleteCard(int setId, int id) async {
    await _service.deleteCard(id);
    await loadCards(setId);
  }

  void markAnswer(bool isCorrect) {
    if (isCorrect) {
      correctAnswers++;
    } else {
      wrongAnswers++;
    }
    notifyListeners();
  }

  Future<void> saveProgress(int setId, {int learnedCards = 0}) async {
    await _service.saveProgress(
      setId: setId,
      totalCards: cards.length,
      learnedCards: learnedCards,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
    );
  }

  void resetQuizStats() {
    correctAnswers = 0;
    wrongAnswers = 0;
    notifyListeners();
  }
}