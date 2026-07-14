import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/session_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/section_header.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>().data;
    final language = context.watch<LanguageProvider>();
    final user = auth.user;
    final answered =
        dashboard.today.correctAnswers + dashboard.today.wrongAnswers;
    final accuracy = answered == 0
        ? 0
        : (dashboard.today.correctAnswers * 100 / answered).round();
    final initial = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().substring(0, 1).toUpperCase()
        : 'L';
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Text(
          language.pick(
            vi: 'Hồ sơ học tập',
            en: 'Study profile',
            ja: '学習プロフィール',
          ),
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: language.pick(
              vi: 'Chỉnh sửa hồ sơ',
              en: 'Edit profile',
              ja: 'プロフィールを編集',
            ),
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          PremiumSurface(
            color: AppColors.navy,
            border: Border.all(color: Colors.transparent),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ivory, width: 3),
                  ),
                  child: user?.avatarUrl == null
                      ? Text(
                          initial,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: AppColors.navy),
                        )
                      : ClipOval(
                          child: Image.network(
                            user!.avatarUrl!,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Text(initial),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ??
                      language.pick(vi: 'Người học', en: 'Learner', ja: '学習者'),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: AppColors.ivory),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ??
                      language.pick(
                        vi: 'Đăng nhập để đồng bộ dữ liệu',
                        en: 'Sign in to sync your data',
                        ja: 'ログインしてデータを同期',
                      ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ivory.withValues(alpha: .62),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _ProfileStat(
                      value: '${dashboard.learnedCards}',
                      label: language.pick(
                        vi: 'Thẻ đã học',
                        en: 'Cards learned',
                        ja: '学習済み',
                      ),
                    ),
                    _ProfileStat(
                      value: '$accuracy%',
                      label: language.pick(
                        vi: 'Đúng hôm nay',
                        en: 'Correct today',
                        ja: '今日の正答率',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: language.pick(
              vi: 'Thành tích',
              en: 'Achievements',
              ja: '実績',
            ),
            subtitle: language.pick(
              vi: 'Dấu mốc trên hành trình của bạn',
              en: 'Milestones on your learning journey',
              ja: '学習の節目',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _AchievementCard(
                  icon: Icons.workspace_premium_outlined,
                  title: language.pick(
                    vi: '100 thẻ đầu tiên',
                    en: 'First 100 cards',
                    ja: '最初の100枚',
                  ),
                  color: AppColors.lavenderDeep,
                  achieved: dashboard.learnedCards >= 100,
                ),
                const SizedBox(width: 10),
                _AchievementCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: language.pick(
                    vi: 'Hoàn thành hôm nay',
                    en: 'Daily goal complete',
                    ja: '今日の目標達成',
                  ),
                  color: AppColors.navyLight,
                  achieved: dashboard.today.learnedCards >= dashboard.dailyGoal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: language.pick(vi: 'Cài đặt', en: 'Settings', ja: '設定'),
          ),
          const SizedBox(height: 12),
          PremiumSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, theme, _) => SwitchListTile(
                    secondary: const _SettingIcon(
                      icon: Icons.dark_mode_outlined,
                      color: AppColors.lavenderDeep,
                    ),
                    title: Text(
                      language.pick(
                        vi: 'Chế độ tối',
                        en: 'Dark mode',
                        ja: 'ダークモード',
                      ),
                    ),
                    subtitle: Text(
                      language.pick(
                        vi: 'Giảm chói khi học trong môi trường tối',
                        en: 'Reduce glare in low-light environments',
                        ja: '暗い場所でのまぶしさを軽減',
                      ),
                    ),
                    value: theme.isDark(context),
                    onChanged: theme.setDarkMode,
                  ),
                ),
                const Divider(indent: 72),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: language.pick(
                    vi: 'Ngôn ngữ',
                    en: 'Language',
                    ja: '言語',
                  ),
                  subtitle: language.language.nativeLabel,
                  color: AppColors.navyLight,
                  onTap: () => _chooseLanguage(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              language.pick(vi: 'Đăng xuất', en: 'Sign out', ja: 'ログアウト'),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Learning Card App · Phiên bản 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final provider = context.read<LanguageProvider>();
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.pick(
                  vi: 'Chọn ngôn ngữ',
                  en: 'Choose language',
                  ja: '言語を選択',
                ),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              RadioGroup<AppLanguage>(
                groupValue: provider.language,
                onChanged: (value) => Navigator.pop(sheetContext, value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppLanguage.values
                      .map(
                        (item) => RadioListTile<AppLanguage>(
                          value: item,
                          title: Text(item.nativeLabel),
                          secondary: Text(switch (item) {
                            AppLanguage.vi => 'VI',
                            AppLanguage.en => 'EN',
                            AppLanguage.ja => '日本',
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await provider.setLanguage(selected);
  }

  Future<void> _logout(BuildContext context) async {
    final language = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: Text(
          language.pick(vi: 'Đăng xuất?', en: 'Sign out?', ja: 'ログアウトしますか？'),
        ),
        content: Text(
          language.pick(
            vi: 'Tiến độ đã đồng bộ vẫn được lưu an toàn trong tài khoản.',
            en: 'Your synced progress remains safely stored in your account.',
            ja: '同期済みの進捗はアカウントに安全に保存されます。',
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(language.pick(vi: 'Ở lại', en: 'Stay', ja: '戻る')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              language.pick(vi: 'Đăng xuất', en: 'Sign out', ja: 'ログアウト'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    SessionState.clearUserData(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.ivory),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ivory.withValues(alpha: .55),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool achieved;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    final lockedLabel = context.watch<LanguageProvider>().pick(
      vi: 'Chưa mở khóa',
      en: 'Locked',
      ja: '未解除',
    );
    return SizedBox(
      width: 142,
      child: PremiumSurface(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              achieved ? icon : Icons.lock_outline_rounded,
              color: achieved
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 25,
            ),
            const Spacer(),
            Text(
              achieved ? title : '$title · $lockedLabel',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SettingIcon(icon: icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
