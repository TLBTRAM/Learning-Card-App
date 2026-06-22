import 'package:flutter/material.dart';

import '../models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF7C6CFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(message.message, style: TextStyle(color: isUser ? Colors.white : const Color(0xFF222222))),
      ),
    );
  }
}