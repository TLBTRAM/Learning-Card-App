import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';
import '../../core/localization/localized_material.dart';
import '../../core/utils/ui_feedback.dart';
import '../../data/sample_study_data.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat_bubble.dart';
import 'ai_history_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom(immediate: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _send([String? suggestion]) async {
    final message = (suggestion ?? _controller.text).trim();
    if (message.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();

    await context.read<ChatProvider>().sendMessage(message);
    if (!mounted) return;

    final provider = context.read<ChatProvider>();
    if (provider.errorMessage != null) {
      UiFeedback.showError(
        context,
        provider.errorMessage,
        fallback: 'Trợ lý đang bận. Bạn thử gửi lại sau nhé.',
      );
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.lavenderSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.lavenderDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'AI Study Assistant',
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đang hoạt động',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử chat',
            icon: const Icon(Icons.history_rounded, color: AppColors.lavenderDeep),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiHistoryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Đoạn chat mới',
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.lavenderDeep),
            onPressed: () {
              context.read<ChatProvider>().startNewSession();
              UiFeedback.showSuccess(context, 'Đã bắt đầu một đoạn hội thoại mới.');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              scrollDirection: Axis.horizontal,
              itemCount: SampleStudyData.aiSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => ActionChip(
                avatar: Icon(_suggestionIcon(index), size: 17),
                label: Text(SampleStudyData.aiSuggestions[index]),
                onPressed: provider.isLoading
                    ? null
                    : () => _send(SampleStudyData.aiSuggestions[index]),
              ),
            ),
          ),
          Expanded(
            child: provider.isHistoryLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.lavenderDeep,
              ),
            )
                : provider.messages.isEmpty
                ? _AiEmptyState(onSuggestion: _send)
                : ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
              itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (_, index) {
                if (provider.isLoading) {
                  if (index == 0) {
                    return const _TypingIndicator();
                  }
                  final messageIndex = provider.messages.length - index;
                  return ChatBubble(message: provider.messages[messageIndex]);
                } else {
                  final messageIndex = provider.messages.length - 1 - index;
                  return ChatBubble(message: provider.messages[messageIndex]);
                }
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: context.tr('Đính kèm ghi chú'),
                    onPressed: () => UiFeedback.showSuccess(
                      context,
                      'Tính năng đính kèm đang kết nối dữ liệu...',
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: provider.isLoading ? null : (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.tr('Hỏi AI về bài học của bạn...'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: context.tr('Gửi'),
                    onPressed: provider.isLoading ? null : () => _send(),
                    icon: provider.isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _suggestionIcon(int index) => const [
    Icons.lightbulb_outline_rounded,
    Icons.style_outlined,
    Icons.quiz_outlined,
    Icons.summarize_outlined,
  ][index];
}

class _AiEmptyState extends StatelessWidget {
  final Function(String) onSuggestion;
  const _AiEmptyState({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.lavenderSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.lavenderDeep, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Chào bạn! Tôi có thể giúp gì hôm nay?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy đặt câu hỏi, dịch thuật, hoặc nhờ tôi tóm tắt bài học giúp bạn nhé!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lavenderSoft.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 24,
              height: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(radius: 2, backgroundColor: AppColors.lavenderDeep),
                  CircleAvatar(radius: 2, backgroundColor: AppColors.lavenderDeep),
                  CircleAvatar(radius: 2, backgroundColor: AppColors.lavenderDeep),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}