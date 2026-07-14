import '../../core/localization/localized_material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 44),
                      const SizedBox(width: 12),
                      Text(
                        'Learning Card',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.cream,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? AppColors.darkLine : AppColors.line,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _EditionPill(),
                        const SizedBox(height: 22),
                        Text(
                          'Kiến thức của bạn,\nđược tổ chức đẹp đẽ.',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Flashcard, ghi chú và trợ lý AI trong một không gian học tập tập trung.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 28),
                        const Row(
                          children: [
                            _Feature(
                              icon: Icons.style_rounded,
                              text: 'Ghi nhớ',
                            ),
                            SizedBox(width: 10),
                            _Feature(
                              icon: Icons.edit_note_rounded,
                              text: 'Ghi chú',
                            ),
                            SizedBox(width: 10),
                            _Feature(
                              icon: Icons.auto_awesome_rounded,
                              text: 'AI học tập',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 52),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      child: const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text('Tạo tài khoản mới'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Bằng cách tiếp tục, bạn đồng ý với Điều khoản sử dụng.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditionPill extends StatelessWidget {
  const _EditionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.brassSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'STUDY EDITION',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.navy,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 21, color: AppColors.lavenderDeep),
          const SizedBox(height: 7),
          Text(
            text,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
