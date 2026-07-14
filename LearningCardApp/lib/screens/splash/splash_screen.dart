import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../auth/welcome_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scale = Tween(begin: .88, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      auth.tryAutoLogin(),
      Future<void>.delayed(const Duration(milliseconds: 1450)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) =>
            auth.isAuthenticated ? const HomeScreen() : const WelcomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackdrop(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    const AppLogo(size: 86, inverted: true),
                    const SizedBox(height: 28),
                    Text(
                      'Learning Card App',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: AppColors.ivory, fontSize: 38),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ghi nhớ sâu hơn. Học tập tinh tế hơn.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ivory.withValues(alpha: .72),
                      ),
                    ),
                    const Spacer(flex: 3),
                    const SizedBox(
                      width: 30,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: AppColors.navyLight,
                        color: AppColors.brass,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang chuẩn bị không gian học tập',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ivory.withValues(alpha: .55),
                      ),
                    ),
                    const SizedBox(height: 36),
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

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashPainter());
  }
}

class _SplashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lavender = Paint()..color = AppColors.lavender.withValues(alpha: .10);
    final brass = Paint()..color = AppColors.brass.withValues(alpha: .08);
    canvas.drawCircle(
      Offset(size.width * .12, size.height * .17),
      130,
      lavender,
    );
    canvas.drawCircle(Offset(size.width * .94, size.height * .74), 170, brass);
    final line = Paint()
      ..color = AppColors.ivory.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double y = 80; y < size.height; y += 48) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
