import 'dart:async';

import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../models/flashcard_set_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/flashcard_set_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/search_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_panel.dart';
import '../ai/ai_chat_screen.dart';
import '../flashcards/create_flashcard_set_screen.dart';
import '../flashcards/flashcard_detail_screen.dart';
import '../flashcards/flashcard_sets_screen.dart';
import '../notes/handwriting_note_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardView(onChangeTab: _changeTab),
      const FlashcardSetsScreen(),
      const HandwritingNoteScreen(),
      const ProfileScreen(),
    ];
  }

  void _changeTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changeTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: language.pick(vi: 'Trang chủ', en: 'Home', ja: 'ホーム'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            selectedIcon: const Icon(Icons.style_rounded),
            label: language.pick(vi: 'Thẻ nhớ', en: 'Flashcards', ja: '単語カード'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note_rounded),
            label: language.pick(vi: 'Ghi chú', en: 'Notes', ja: 'ノート'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: language.pick(vi: 'Hồ sơ', en: 'Profile', ja: 'プロフィール'),
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  final ValueChanged<int> onChangeTab;

  const DashboardView({super.key, required this.onChangeTab});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<DashboardProvider>().loadDashboard(),
      context.read<FlashcardSetProvider>().loadSets(),
      context.read<NoteProvider>().loadNotes(),
    ]);
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      context.read<SearchProvider>().clear();
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 220),
      () => context.read<SearchProvider>().search(value),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        titleSpacing: 20,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: context.tr('Tìm bộ thẻ, thuật ngữ hoặc ghi chú...'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('Xóa tìm kiếm'),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const AiChatScreen()),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text('AI'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _query.trim().isNotEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'create-set-home',
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateFlashcardSetScreen(),
                  ),
                );
                if (mounted) _refresh();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo bộ thẻ'),
            ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            if (_query.trim().isNotEmpty)
              const _SearchResultsPanel()
            else if (dashboard.isLoading && dashboard.data.totalSets == 0)
              const _DashboardSkeleton()
            else if (dashboard.errorMessage != null &&
                dashboard.data.totalSets == 0)
              SizedBox(
                height: 420,
                child: StatePanel(
                  icon: Icons.cloud_off_outlined,
                  title: 'Chưa tải được Dashboard',
                  message:
                      'Hãy kiểm tra backend và migration dữ liệu rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: _refresh,
                ),
              )
            else
              _DashboardContent(
                onChangeTab: widget.onChangeTab,
                onRefresh: _refresh,
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final ValueChanged<int> onChangeTab;
  final Future<void> Function() onRefresh;

  const _DashboardContent({required this.onChangeTab, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DashboardProvider>().data;
    final recentSets = data.recentSets;
    final todayProgress = data.dailyGoal == 0
        ? 0.0
        : (data.today.learnedCards / data.dailyGoal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContinueLearningCard(
          set: recentSets.isEmpty ? null : recentSets.first,
          onTap: recentSets.isEmpty
              ? () => onChangeTab(1)
              : () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        FlashcardDetailScreen(flashcardSet: recentSets.first),
                  ),
                ),
        ),
        const SizedBox(height: 26),
        const SectionHeader(
          title: 'Hoạt động hôm nay',
          subtitle: 'Được tính từ các phiên học bạn đã hoàn thành',
        ),
        const SizedBox(height: 14),
        PremiumSurface(
          child: Row(
            children: [
              SizedBox(
                width: 66,
                height: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: todayProgress,
                      strokeWidth: 7,
                      backgroundColor: AppColors.lavenderSoft,
                    ),
                    Text(
                      '${(todayProgress * 100).round()}%',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.today.learnedCards}/${data.dailyGoal} thẻ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data.today.sessions} phiên · ${data.today.correctAnswers} câu đúng · ${data.today.wrongAnswers} câu sai',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  width: width,
                  icon: Icons.collections_bookmark_outlined,
                  value: '${data.totalSets}',
                  label:
                      '${data.ownedSets} của bạn · ${data.sharedSets} được chia sẻ',
                  color: AppColors.lavenderDeep,
                ),
                _StatCard(
                  width: width,
                  icon: Icons.done_all_rounded,
                  value: '${data.learnedCards}',
                  label: 'Thẻ đã thực sự học',
                  color: AppColors.success,
                ),
                _StatCard(
                  width: constraints.maxWidth,
                  icon: Icons.edit_note_outlined,
                  value: '${data.ownedNotes + data.sharedNotes}',
                  label:
                      '${data.ownedNotes} của bạn · ${data.sharedNotes} được chia sẻ',
                  color: AppColors.brass,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        SectionHeader(
          title: 'Bộ thẻ gần đây',
          actionLabel: 'Xem tất cả',
          onAction: () => onChangeTab(1),
        ),
        const SizedBox(height: 14),
        if (recentSets.isEmpty)
          SizedBox(
            height: 210,
            child: StatePanel(
              icon: Icons.style_outlined,
              title: 'Chưa có bộ thẻ',
              message: 'Tạo bộ đầu tiên hoặc mở một bộ được chia sẻ với bạn.',
              actionLabel: 'Mở thư viện',
              onAction: () => onChangeTab(1),
            ),
          )
        else
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentSets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) => _RecentSetCard(set: recentSets[index]),
            ),
          ),
        const SizedBox(height: 28),
        _AiAssistantCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AiChatScreen()),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 22),
        child: Column(
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 14),
            Text('Đang tìm trong bộ thẻ, từng thẻ nhớ và ghi chú...'),
          ],
        ),
      );
    }
    if (provider.errorMessage != null) {
      return SizedBox(
        height: 300,
        child: StatePanel(
          icon: Icons.search_off_rounded,
          title: 'Chưa tìm kiếm được',
          message: 'Kết nối đang gián đoạn. Hãy thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => provider.search(provider.activeQuery),
        ),
      );
    }
    final results = provider.results;
    if (results.isEmpty) {
      return const SizedBox(
        height: 300,
        child: StatePanel(
          icon: Icons.manage_search_rounded,
          title: 'Không có kết quả',
          message:
              'Không tìm thấy trong dữ liệu của bạn, nội dung được chia sẻ hoặc công khai.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.totalCount} kết quả',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Kết quả xuất hiện ngay bên dưới ô tìm kiếm',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (results.sets.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SearchSectionLabel(
            icon: Icons.collections_bookmark_outlined,
            label: 'Bộ flashcard',
          ),
          const SizedBox(height: 8),
          ...results.sets.map(
            (set) => _SearchTile(
              icon: Icons.style_rounded,
              title: set.title,
              subtitle:
                  '${set.cardCount} thẻ · Tạo bởi ${set.ownerName.isEmpty ? 'bạn' : set.ownerName}',
              badge: set.isOwner
                  ? 'Của bạn'
                  : set.accessType == 'public'
                  ? 'Công khai'
                  : 'Được chia sẻ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => FlashcardDetailScreen(flashcardSet: set),
                ),
              ),
            ),
          ),
        ],
        if (results.cards.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SearchSectionLabel(
            icon: Icons.view_agenda_outlined,
            label: 'Thẻ nhớ',
          ),
          const SizedBox(height: 8),
          ...results.cards.map(
            (result) => _SearchTile(
              icon: Icons.crop_landscape_rounded,
              title: result.card.front,
              subtitle:
                  '${result.card.back} · ${result.set.title} · Tạo bởi ${result.set.ownerName}',
              badge: 'Thẻ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      FlashcardDetailScreen(flashcardSet: result.set),
                ),
              ),
            ),
          ),
        ],
        if (results.notes.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SearchSectionLabel(
            icon: Icons.edit_note_outlined,
            label: 'Ghi chú',
          ),
          const SizedBox(height: 8),
          ...results.notes.map(
            (note) => _SearchTile(
              icon: note.drawingData.isEmpty
                  ? Icons.notes_rounded
                  : Icons.gesture_rounded,
              title: note.title,
              subtitle:
                  '${note.contentText.isEmpty ? 'Ghi chú viết tay' : note.contentText} · Tạo bởi ${note.ownerName.isEmpty ? 'bạn' : note.ownerName}',
              badge: note.isOwner ? 'Của bạn' : 'Được chia sẻ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => HandwritingNoteScreen(noteToLoad: note),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SearchSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.lavenderDeep),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _SearchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _SearchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: PremiumSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lavenderSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.lavenderDeep, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              badge,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.lavenderDeep),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final FlashcardSet? set;
  final VoidCallback onTap;

  const _ContinueLearningCard({required this.set, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = (set?.progressPercent ?? 0) / 100;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIẾP TỤC HỌC',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.brass,
                              letterSpacing: .8,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        set?.title ?? 'Bắt đầu bộ thẻ đầu tiên',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: AppColors.ivory),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        set == null
                            ? 'Tạo bộ thẻ hoặc mở nội dung được chia sẻ'
                            : '${set!.cardCount} thẻ · Tạo bởi ${set!.ownerName.isEmpty ? 'bạn' : set!.ownerName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ivory.withValues(alpha: .66),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: AppColors.navyLight,
                        color: AppColors.brass,
                      ),
                    ),
                    Text(
                      '${set?.progressPercent ?? 0}%',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: AppColors.ivory),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PremiumSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 14),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSetCard extends StatelessWidget {
  final FlashcardSet set;

  const _RecentSetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: PremiumSurface(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FlashcardDetailScreen(flashcardSet: set),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    size: 19,
                    color: AppColors.lavenderDeep,
                  ),
                ),
                const Spacer(),
                if (!set.isOwner)
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 18,
                    color: AppColors.lavenderDeep,
                  )
                else
                  const Icon(Icons.lock_outline_rounded, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              set.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              '${set.cardCount} thẻ · ${set.ownerName.isEmpty ? 'Bạn tạo' : 'Tạo bởi ${set.ownerName}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AiAssistantCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumSurface(
      onTap: onTap,
      color: isDark ? AppColors.darkSurfaceHigh : AppColors.lavenderSoft,
      border: Border.all(color: Colors.transparent),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.lavenderDeep,
            size: 28,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý học tập AI',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'Giải thích, tóm tắt và tạo quiz',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          height: index == 0 ? 170 : 112,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}
