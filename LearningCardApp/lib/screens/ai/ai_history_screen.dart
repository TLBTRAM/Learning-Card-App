import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_surface.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final currentSessionId = provider.currentSessionId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử trò chuyện'),
        centerTitle: true,
      ),
      body: provider.isHistoryLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.lavenderDeep),
      )
          : provider.sessions.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: provider.sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = provider.sessions[index];
          final isCurrentActive = currentSessionId == session.id;
          String dateString = '';
          try {
            final DateTime rawDateTime = session.createdAt is String
                ? DateTime.parse(session.createdAt as String)
                : session.createdAt;
            final DateTime localDateTime = rawDateTime.toLocal();
            dateString = DateFormat('HH:mm - dd/MM/yyyy').format(localDateTime);
          } catch (e) {
            dateString = session.createdAt.toString();
          }

          return Dismissible(
            key: Key(session.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa hội thoại?'),
                  content: const Text('Bạn có chắc chắn muốn xóa vĩnh viễn đoạn hội thoại này không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) {
              context.read<ChatProvider>().deleteSession(session.id);
            },
            child: PremiumSurface(
              onTap: () async {
                if (isCurrentActive) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context);
                context.read<ChatProvider>().selectSession(session.id);
              },
              color: isCurrentActive
                  ? AppColors.lavenderSoft.withValues(alpha: .5)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isCurrentActive ? AppColors.lavenderDeep : Theme.of(context).colorScheme.outlineVariant,
                width: isCurrentActive ? 1.5 : 1.0,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentActive ? AppColors.lavenderDeep : AppColors.lavenderSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCurrentActive ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                      color: isCurrentActive ? Colors.white : AppColors.lavenderDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isCurrentActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lavenderDeep.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateString,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isCurrentActive
                                ? AppColors.lavenderDeep.withValues(alpha: .8)
                                : AppColors.slate,
                            fontWeight: isCurrentActive ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isCurrentActive ? AppColors.lavenderDeep : AppColors.slate,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.lavenderSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              color: AppColors.lavenderDeep,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text('Chưa có đoạn trò chuyện nào'),
        ],
      ),
    );
  }
}