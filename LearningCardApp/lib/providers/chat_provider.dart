import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
  });
}

class ChatProvider extends ChangeNotifier {
  final AiService _service = AiService();
  final _uuid = const Uuid();

  String? _currentSessionId;
  List<ChatMessageModel> messages = [];
  List<ChatSession> sessions = [];

  bool isLoading = false;
  bool isHistoryLoading = false;
  String? errorMessage;
  String get currentSessionId {
    _currentSessionId ??= _uuid.v4();
    return _currentSessionId!;
  }

  void startNewSession() {
    _currentSessionId = _uuid.v4();
    messages.clear();
    errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _currentSessionId = null;
    messages.clear();
    sessions.clear();
    isLoading = false;
    isHistoryLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return;

    final activeSessionId = currentSessionId;

    messages.add(ChatMessageModel(
      role: 'user',
      message: cleanMessage,
      createdAt: DateTime.now(),
    ));

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final answer = await _service.sendMessage(cleanMessage, activeSessionId);
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
        message: "Không thể nhận câu trả lời từ AI lúc này: $cleanError",
        createdAt: DateTime.now(),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessions() async {
    isHistoryLoading = true;
    notifyListeners();
    try {
      final list = await _service.getSessions();
      sessions = list.map((item) => ChatSession(
        id: item['id'],
        title: item['title'],
        createdAt: DateTime.parse(item['createdAt']),
      )).toList();
    } catch (_) {
      sessions = [];
    } finally {
      isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectSession(String sessionId) async {
    _currentSessionId = sessionId;
    isHistoryLoading = true;
    messages.clear();
    notifyListeners();

    try {
      final list = await _service.getSessionMessages(sessionId);
      messages = list.map((item) => ChatMessageModel(
        role: item['role'],
        message: item['message'],
        createdAt: DateTime.parse(item['createdAt']),
      )).toList();
    } catch (_) {
      messages = [];
    } finally {
      isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _service.deleteSession(sessionId);
      if (_currentSessionId == sessionId) {
        startNewSession();
      } else {
        await loadSessions();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}