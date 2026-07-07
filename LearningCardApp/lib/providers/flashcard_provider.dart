import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardService _flashcardService = FlashcardService();

  List<Flashcard> _cards = [];
  List<Flashcard> get cards => _cards;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int correctAnswers = 0;
  int wrongAnswers = 0;

  Future<void> loadCards(int setId) async {
    _isLoading = true;
    notifyListeners();
    _cards = await _flashcardService.getCardsBySet(setId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createCard({required int setId, required String front, required String back, String example = ''}) async {
    await _flashcardService.createCard(setId: setId, front: front, back: back, example: example);
    await loadCards(setId);
  }

  Future<void> updateCard({
    required int setId,
    required int cardId,
    required String front,
    required String back,
    String example = ''
  }) async {
    await _flashcardService.updateCard(id: cardId, front: front, back: back, example: example);
    await loadCards(setId);
    notifyListeners();
  }

  Future<void> addCard(int setId, String front, String back) async {
    await _flashcardService.addCard(setId, front, back);
    await loadCards(setId);
  }

  Future<void> deleteCard(int setId, int id) async {
    await _flashcardService.deleteCard(id);
    await loadCards(setId);
  }

  Future<void> saveProgress({
    required int setId,
    required int totalCards,
    required int learnedCards,
    required int correctAnswers,
    required int wrongAnswers,
  }) async {
    await _flashcardService.saveProgress(
      setId: setId,
      totalCards: totalCards,
      learnedCards: learnedCards,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
    );
  }

  void markAnswer(bool isCorrect) {
    if (isCorrect) correctAnswers++; else wrongAnswers++;
    notifyListeners();
  }

  void resetQuizStats() {
    correctAnswers = 0;
    wrongAnswers = 0;
    notifyListeners();
  }
}