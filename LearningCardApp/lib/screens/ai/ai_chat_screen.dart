import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../widgets/chat_bubble.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();

  Future<void> _send() async {
    final message = _controller.text.trim();
    _controller.clear();
    await context.read<ChatProvider>().sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Chat'),
        actions: [IconButton(onPressed: () => context.read<ChatProvider>().clear(), icon: const Icon(Icons.delete_outline))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _PromptChip(text: 'Explain photosynthesis', onTap: (text) { _controller.text = text; _send(); }),
                _PromptChip(text: 'Summarize my biology note', onTap: (text) { _controller.text = text; _send(); }),
                _PromptChip(text: 'Create 5 flashcards from this paragraph', onTap: (text) { _controller.text = text; _send(); }),
              ],
            ),
          ),
          Expanded(
            child: provider.messages.isEmpty
                ? const Center(child: Text('Chua co doan chat. Hay hoi AI ve bai hoc cua ban.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.messages.length,
                    itemBuilder: (_, index) => ChatBubble(message: provider.messages[index]),
                  ),
          ),
          if (provider.isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Nhap cau hoi hoc tap'))),
                const SizedBox(width: 12),
                FloatingActionButton.small(onPressed: _send, child: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTap;

  const _PromptChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(label: Text(text), onPressed: () => onTap(text)),
    );
  }
}