import '../core/localization/localized_material.dart';

import '../models/chat_message_model.dart';
import '../theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
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
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.navy
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(19),
                  topRight: const Radius.circular(19),
                  bottomLeft: Radius.circular(isUser ? 19 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 19),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .035),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser ? AppColors.ivory : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: isUser
                          ? AppColors.ivory.withValues(alpha: .5)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
