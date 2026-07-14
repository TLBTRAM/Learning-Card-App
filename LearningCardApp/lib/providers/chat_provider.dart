import 'package:flutter/material.dart';

import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final AiService _service = AiService();

  final List<ChatMessageModel> messages = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    messages.add(
      ChatMessageModel(
        role: 'user',
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final answer = await _service.sendMessage(message);
      messages.add(
        ChatMessageModel(
          role: 'assistant',
          message: answer,
          createdAt: DateTime.now(),
        ),
      );
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    messages.clear();
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}
