import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../models/flashcard_model.dart';
import '../../models/flashcard_set_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/flashcard_set_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/section_header.dart';
import '../../widgets/share_sheet.dart';
import '../../widgets/state_panel.dart';
import 'create_flashcard_screen.dart';
import 'edit_flashcard_screen.dart';
import 'quiz_mode_screen.dart';
import 'study_mode_screen.dart';

class FlashcardDetailScreen extends StatefulWidget {
  final FlashcardSet flashcardSet;

  const FlashcardDetailScreen({super.key, required this.flashcardSet});

  @override
  State<FlashcardDetailScreen> createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadCards(widget.flashcardSet.id);
    });
  }

  Future<void> _openCreateCard() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CreateFlashcardScreen(setId: widget.flashcardSet.id),
      ),
    );
    if (mounted) {
      context.read<FlashcardProvider>().loadCards(widget.flashcardSet.id);
    }
  }

  void _openStudy(List<Flashcard> cards) {
    if (cards.isEmpty) {
      UiFeedback.showError(
        context,
        null,
        fallback: 'Hãy thêm ít nhất một thẻ trước khi bắt đầu học.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => StudyModeScreen(cards: cards)),
    );
  }

  void _openQuiz(List<Flashcard> cards) {
    if (cards.isEmpty) {
      UiFeedback.showError(
        context,
        null,
        fallback: 'Hãy thêm thẻ trước khi tạo bài quiz.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => QuizModeScreen(
          cards: cards,
          setId: widget.flashcardSet.id,
          title: widget.flashcardSet.title,
        ),
      ),
    );
  }

  Future<void> _deleteCard(Flashcard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        title: const Text('Xóa thẻ này?'),
        content: Text('“${card.front}” sẽ được xóa khỏi bộ flashcard.'),
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
    if (confirmed != true || !mounted) return;
    try {
      await context.read<FlashcardProvider>().deleteCard(
        widget.flashcardSet.id,
        card.id,
      );
      if (mounted) UiFeedback.showSuccess(context, 'Đã xóa thẻ.');
    } catch (error) {
      if (mounted) {
        UiFeedback.showError(
          context,
          error,
          fallback: 'Chưa thể xóa thẻ lúc này.',
        );
      }
    }
  }

  Future<void> _editSet() async {
    final title = TextEditingController(text: widget.flashcardSet.title);
    final description = TextEditingController(
      text: widget.flashcardSet.description,
    );
    final setProvider = context.read<FlashcardSetProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chỉnh sửa thông tin',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: title,
              decoration: InputDecoration(labelText: context.tr('Tên bộ thẻ')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.tr('Mô tả')),
            ),
            const SizedBox(height: 18),
            AppButton(
              text: 'Lưu thay đổi',
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                try {
                  await setProvider.updateSet(
                    id: widget.flashcardSet.id,
                    title: title.text.trim(),
                    description: description.text.trim(),
                    color: widget.flashcardSet.color,
                  );
                  if (!sheetContext.mounted || !mounted) return;
                  Navigator.pop(sheetContext);
                  UiFeedback.showSuccess(context, 'Đã cập nhật bộ thẻ.');
                } catch (error) {
                  if (mounted) UiFeedback.showError(context, error);
                }
              },
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
  }

  Future<void> _shareSet() async {
    final provider = context.read<FlashcardSetProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ShareSheet(
        resourceName: 'bộ flashcard',
        initialVisibility: widget.flashcardSet.visibility,
        loadRecipients: () => provider.getShares(widget.flashcardSet.id),
        shareWithEmail: (email) =>
            provider.shareWithEmail(widget.flashcardSet.id, email),
        revokeShare: (userId) =>
            provider.revokeShare(widget.flashcardSet.id, userId),
        updateVisibility: (visibility) =>
            provider.updateVisibility(widget.flashcardSet.id, visibility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bộ thẻ'),
        actions: [
          if (widget.flashcardSet.isOwner) ...[
            IconButton(
              tooltip: context.tr('Chia sẻ bộ thẻ'),
              onPressed: _shareSet,
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              tooltip: context.tr('Chỉnh sửa bộ thẻ'),
              onPressed: _editSet,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: widget.flashcardSet.isOwner
          ? FloatingActionButton.extended(
              onPressed: _openCreateCard,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm thẻ'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => provider.loadCards(widget.flashcardSet.id),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            _SetOverview(
              set: widget.flashcardSet,
              cardCount: provider.cards.length,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openStudy(provider.cards),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Học ngay'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openQuiz(provider.cards),
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Quiz'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Danh sách từ vựng',
              subtitle: '${provider.cards.length} thẻ',
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              ...List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _CardSkeleton(),
                ),
              )
            else if (provider.errorMessage != null && provider.cards.isEmpty)
              SizedBox(
                height: 260,
                child: StatePanel(
                  icon: Icons.cloud_off_outlined,
                  title: 'Chưa tải được nội dung',
                  message: 'Kết nối đang gián đoạn. Bạn thử lại nhé.',
                  actionLabel: 'Thử lại',
                  onAction: () => provider.loadCards(widget.flashcardSet.id),
                ),
              )
            else if (provider.cards.isEmpty)
              SizedBox(
                height: 280,
                child: StatePanel(
                  icon: Icons.add_card_outlined,
                  title: 'Bộ thẻ chưa có nội dung',
                  message: widget.flashcardSet.isOwner
                      ? 'Thêm thuật ngữ đầu tiên để bắt đầu phiên học.'
                      : 'Chủ sở hữu chưa thêm nội dung vào bộ này.',
                  actionLabel: widget.flashcardSet.isOwner
                      ? 'Thêm thẻ đầu tiên'
                      : null,
                  onAction: widget.flashcardSet.isOwner
                      ? _openCreateCard
                      : null,
                ),
              )
            else
              ...provider.cards.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VocabularyCard(
                    index: entry.key,
                    card: entry.value,
                    canEdit: widget.flashcardSet.isOwner,
                    onEdit: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EditFlashcardScreen(
                            setId: widget.flashcardSet.id,
                            card: entry.value,
                          ),
                        ),
                      );
                      if (mounted) {
                        provider.loadCards(widget.flashcardSet.id);
                      }
                    },
                    onDelete: () => _deleteCard(entry.value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SetOverview extends StatelessWidget {
  final FlashcardSet set;
  final int cardCount;

  const _SetOverview({required this.set, required this.cardCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$cardCount THẺ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.brass,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.bookmark_border_rounded, color: AppColors.ivory),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            set.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.ivory),
          ),
          if (set.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              set.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ivory.withValues(alpha: .68),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                set.isOwner
                    ? Icons.person_outline_rounded
                    : Icons.people_alt_outlined,
                size: 16,
                color: AppColors.brass,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tạo bởi ${set.ownerName.isEmpty ? 'bạn' : set.ownerName}${set.isOwner ? ' · Bạn là chủ sở hữu' : ' · Chỉ có quyền xem và học'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ivory.withValues(alpha: .72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: .58,
                    minHeight: 7,
                    backgroundColor: AppColors.navyLight,
                    color: AppColors.brass,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '58%',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.ivory),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  final int index;
  final Flashcard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canEdit;

  const _VocabularyCard({
    required this.index,
    required this.card,
    required this.onEdit,
    required this.onDelete,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lavenderSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.lavenderDeep),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.front,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  card.back,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (card.example.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '“${card.example}”',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lavenderDeep,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xóa thẻ')),
              ],
            ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      child: SizedBox(
        height: 72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
