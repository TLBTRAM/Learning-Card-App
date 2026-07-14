import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../models/flashcard_set_model.dart';
import '../../providers/flashcard_set_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/share_sheet.dart';
import '../../widgets/state_panel.dart';
import 'create_flashcard_set_screen.dart';
import 'flashcard_detail_screen.dart';

class FlashcardSetsScreen extends StatefulWidget {
  const FlashcardSetsScreen({super.key});

  @override
  State<FlashcardSetsScreen> createState() => _FlashcardSetsScreenState();
}

class _FlashcardSetsScreenState extends State<FlashcardSetsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardSetProvider>().loadSets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const CreateFlashcardSetScreen()),
    );
    if (mounted) context.read<FlashcardSetProvider>().loadSets();
  }

  Future<void> _editSet(FlashcardSet set) async {
    final title = TextEditingController(text: set.title);
    final description = TextEditingController(text: set.description);
    final formKey = GlobalKey<FormState>();
    final setProvider = context.read<FlashcardSetProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          6,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chỉnh sửa bộ thẻ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: title,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? context.tr('Tên bộ thẻ không được để trống')
                    : null,
                decoration: InputDecoration(
                  labelText: context.tr('Tên bộ thẻ'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                maxLines: 3,
                decoration: InputDecoration(labelText: context.tr('Mô tả')),
              ),
              const SizedBox(height: 18),
              AppButton(
                text: 'Lưu thay đổi',
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  try {
                    await setProvider.updateSet(
                      id: set.id,
                      title: title.text.trim(),
                      description: description.text.trim(),
                      color: set.color,
                    );
                    if (!sheetContext.mounted || !mounted) return;
                    Navigator.pop(sheetContext);
                    UiFeedback.showSuccess(context, 'Đã cập nhật bộ thẻ.');
                  } catch (error) {
                    if (mounted) {
                      UiFeedback.showError(
                        context,
                        error,
                        fallback: 'Chưa thể cập nhật bộ thẻ.',
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    title.dispose();
    description.dispose();
  }

  Future<void> _deleteSet(FlashcardSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        title: const Text('Xóa bộ flashcard?'),
        content: Text(
          '“${set.title}” và toàn bộ thẻ bên trong sẽ bị xóa. Thao tác này không thể hoàn tác.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa bộ thẻ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<FlashcardSetProvider>().deleteSet(set.id);
      if (mounted) UiFeedback.showSuccess(context, 'Đã xóa bộ thẻ.');
    } catch (error) {
      if (mounted) {
        UiFeedback.showError(
          context,
          error,
          fallback: 'Chưa thể xóa bộ thẻ lúc này.',
        );
      }
    }
  }

  Future<void> _shareSet(FlashcardSet set) async {
    final provider = context.read<FlashcardSetProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ShareSheet(
        resourceName: 'bộ flashcard',
        initialVisibility: set.visibility,
        loadRecipients: () => provider.getShares(set.id),
        shareWithEmail: (email) => provider.shareWithEmail(set.id, email),
        revokeShare: (userId) => provider.revokeShare(set.id, userId),
        updateVisibility: (visibility) =>
            provider.updateVisibility(set.id, visibility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardSetProvider>();
    final sets = provider.sets
        .where((set) => set.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thư viện flashcard'),
            Text(
              '${provider.sets.length} bộ thẻ trong thư viện',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-set-library',
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo bộ thẻ'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: context.tr('Tìm trong thư viện...'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(child: _buildBody(provider, sets)),
        ],
      ),
    );
  }

  Widget _buildBody(FlashcardSetProvider provider, List<FlashcardSet> sets) {
    if (provider.isLoading && provider.sets.isEmpty) {
      return const SkeletonList();
    }
    if (provider.errorMessage != null && provider.sets.isEmpty) {
      return StatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'Không thể mở thư viện',
        message: 'Hãy kiểm tra kết nối và thử tải lại.',
        actionLabel: 'Thử lại',
        onAction: provider.loadSets,
      );
    }
    if (sets.isEmpty) {
      return StatePanel(
        icon: Icons.collections_bookmark_outlined,
        title: _query.isEmpty ? 'Thư viện đang trống' : 'Không tìm thấy bộ thẻ',
        message: _query.isEmpty
            ? 'Tạo bộ flashcard đầu tiên để bắt đầu học có hệ thống.'
            : 'Thử tìm kiếm bằng một từ khóa khác.',
        actionLabel: _query.isEmpty ? 'Tạo bộ flashcard' : null,
        onAction: _query.isEmpty ? _openCreate : null,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadSets,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 2 : 1;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 108),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.9,
            ),
            itemCount: sets.length,
            itemBuilder: (_, index) => _SetTile(
              set: sets[index],
              onEdit: () => _editSet(sets[index]),
              onShare: () => _shareSet(sets[index]),
              onDelete: () => _deleteSet(sets[index]),
            ),
          );
        },
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  final FlashcardSet set;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _SetTile({
    required this.set,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _parseColor(set.color);
    return PremiumSurface(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => FlashcardDetailScreen(flashcardSet: set),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.style_rounded, color: accent),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        set.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (set.isOwner)
                      PopupMenuButton<String>(
                        tooltip: context.tr('Tùy chọn'),
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'share') onShare();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Chỉnh sửa'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.ios_share_outlined),
                              title: Text('Chia sẻ'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                              title: Text('Xóa bộ thẻ'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Được chia sẻ',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.lavenderDeep),
                        ),
                      ),
                  ],
                ),
                Text(
                  set.description.isEmpty
                      ? 'Bộ flashcard học tập'
                      : set.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${set.cardCount} thẻ · Tạo bởi ${set.ownerName.isEmpty ? 'bạn' : set.ownerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String value) {
    try {
      return Color(int.parse(value.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return AppColors.lavenderDeep;
    }
  }
}
