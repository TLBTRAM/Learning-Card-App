import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/share_sheet.dart';
import '../../widgets/state_panel.dart';

class SavedNotesScreen extends StatefulWidget {
  final ValueChanged<NoteModel> onNoteTap;

  const SavedNotesScreen({super.key, required this.onNoteTap});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        final notes = provider.notes.where((note) {
          final query = _query.toLowerCase();
          return note.title.toLowerCase().contains(query) ||
              note.contentText.toLowerCase().contains(query) ||
              note.ownerName.toLowerCase().contains(query);
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: context.tr('Tìm tiêu đề hoặc nội dung ghi chú...'),
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
            Expanded(child: _buildBody(provider, notes)),
          ],
        );
      },
    );
  }

  Widget _buildBody(NoteProvider provider, List<NoteModel> notes) {
    if (provider.isLoading && provider.notes.isEmpty) {
      return const SkeletonList(itemCount: 3);
    }
    if (provider.errorMessage != null && provider.notes.isEmpty) {
      return StatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'Chưa mở được sổ tay',
        message: 'Kết nối đang gián đoạn. Bạn thử lại nhé.',
        actionLabel: 'Thử lại',
        onAction: provider.loadNotes,
      );
    }
    if (notes.isEmpty) {
      return StatePanel(
        icon: _query.isEmpty
            ? Icons.edit_note_outlined
            : Icons.search_off_rounded,
        title: _query.isEmpty
            ? 'Chưa có ghi chú nào'
            : 'Không tìm thấy ghi chú',
        message: _query.isEmpty
            ? 'Tạo trang viết đầu tiên để lưu lại ý tưởng và kiến thức.'
            : 'Kết quả được lọc ngay theo tiêu đề, nội dung và người tạo.',
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadNotes,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = notes[index];
          return PremiumSurface(
            onTap: () => widget.onNoteTap(note),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 58,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? AppColors.brassSoft
                        : AppColors.lavenderSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    note.drawingData.isEmpty
                        ? Icons.notes_rounded
                        : Icons.gesture_rounded,
                    color: index.isEven
                        ? AppColors.warning
                        : AppColors.lavenderDeep,
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
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (!note.isOwner)
                            const Icon(
                              Icons.people_alt_outlined,
                              size: 17,
                              color: AppColors.lavenderDeep,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.contentText.isEmpty
                            ? 'Ghi chú viết tay'
                            : note.contentText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tạo bởi ${note.ownerName.isEmpty ? 'bạn' : note.ownerName}${note.isOwner ? '' : ' · Chỉ đọc'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: note.isOwner
                              ? AppColors.success
                              : AppColors.lavenderDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'open') widget.onNoteTap(note);
                    if (value == 'share') _share(provider, note);
                    if (value == 'delete') _delete(provider, note);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('Mở ghi chú'),
                    ),
                    if (note.isOwner)
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Chia sẻ'),
                      ),
                    if (note.isOwner)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa ghi chú'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _share(NoteProvider provider, NoteModel note) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ShareSheet(
        resourceName: 'ghi chú',
        initialVisibility: note.visibility,
        loadRecipients: () => provider.getShares(note.id),
        shareWithEmail: (email) => provider.shareWithEmail(note.id, email),
        revokeShare: (userId) => provider.revokeShare(note.id, userId),
        updateVisibility: (visibility) =>
            provider.updateVisibility(note.id, visibility),
      ),
    );
  }

  Future<void> _delete(NoteProvider provider, NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        title: const Text('Xóa ghi chú?'),
        content: Text('“${note.title}” sẽ bị xóa vĩnh viễn.'),
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
      await provider.deleteNote(note.id);
      if (mounted) UiFeedback.showSuccess(context, 'Đã xóa ghi chú.');
    } catch (error) {
      if (mounted) {
        UiFeedback.showError(
          context,
          error,
          fallback: 'Chưa thể xóa ghi chú lúc này.',
        );
      }
    }
  }
}
