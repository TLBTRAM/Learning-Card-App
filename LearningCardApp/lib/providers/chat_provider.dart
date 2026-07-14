import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final AiService _service = AiService();

  final List<ChatMessageModel> messages = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> sendMessage(String message) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return;

    messages.add(ChatMessageModel(
      role: 'user',
      message: cleanMessage,
      createdAt: DateTime.now(),
    ));

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final answer = await _service.sendMessage(cleanMessage);
      messages.add(ChatMessageModel(
        role: 'assistant',
        message: answer,
        createdAt: DateTime.now(),
      ));
    } catch (error) {
      String cleanError = error.toString().replaceFirst('Exception: ', '');
      errorMessage = cleanError;
      messages.add(ChatMessageModel(
        role: 'assistant',
        message: "Xin lỗi, trợ lý gặp sự cố: $cleanError",
        createdAt: DateTime.now(),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    messages.clear();
    errorMessage = null;
    notifyListeners();
  }
}