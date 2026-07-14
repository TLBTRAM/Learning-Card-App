import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../data/sample_study_data.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/premium_surface.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
        fallback: 'Trợ lý đang bận. Bạn thử gửi lại sau một chút nhé.',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: const Text('Xóa cuộc trò chuyện?'),
        content: const Text(
          'Các tin nhắn hiện tại sẽ được xóa khỏi màn hình.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) context.read<ChatProvider>().clear();
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Study Assistant'),
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
                      'Sẵn sàng hỗ trợ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Xóa trò chuyện'),
            onPressed: provider.messages.isEmpty ? null : _clearChat,
            icon: const Icon(Icons.delete_outline_rounded),
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
            child: provider.messages.isEmpty
                ? _AiEmptyState(onSuggestion: _send)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    itemCount:
                        provider.messages.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index == provider.messages.length) {
                        return const _TypingIndicator();
                      }
                      return ChatBubble(message: provider.messages[index]);
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
                      'Khu vực đính kèm đã sẵn sàng để kết nối.',
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
  final ValueChanged<String> onSuggestion;

  const _AiEmptyState({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: AppColors.lavenderSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.lavenderDeep,
              size: 36,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Hôm nay bạn muốn\nhọc điều gì?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Mình có thể giải thích khái niệm, tạo flashcard, tạo quiz hoặc tóm tắt ghi chú.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          ...SampleStudyData.aiSuggestions
              .take(3)
              .map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumSurface(
                    onTap: () => onSuggestion(suggestion),
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.lavenderDeep,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(suggestion)),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.lavenderSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.lavenderDeep,
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => Row(
              children: List.generate(
                3,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderDeep.withValues(
                      alpha:
                          .3 +
                          (((_controller.value * 3 - index).abs() < .55)
                              ? .7
                              : 0),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
