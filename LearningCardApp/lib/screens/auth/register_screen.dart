import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      UiFeedback.showError(
        context,
        null,
        fallback: 'Bạn cần đồng ý với điều khoản để tiếp tục.',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      UiFeedback.showSuccess(
        context,
        'Tạo tài khoản thành công. Hãy đăng nhập!',

      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    } else {
      UiFeedback.showError(
        context,
        auth.errorMessage,
        fallback: 'Chưa thể tạo tài khoản. Vui lòng thử lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Text(
                'Tạo không gian\nhọc của riêng bạn.',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Bắt đầu miễn phí và đồng bộ tiến độ trên mọi thiết bị.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value ?? '').trim().length < 2
                    ? context.tr('Vui lòng nhập họ tên')
                    : null,
                decoration: InputDecoration(
                  labelText: context.tr('Họ và tên'),
                  hintText: context.tr('Nguyễn Minh Anh'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return context.tr('Vui lòng nhập email');
                  if (!RegExp(r'^[\w-.]+@[\w-]+\.[\w-.]+$').hasMatch(email)) {
                    return context.tr('Email chưa đúng định dạng');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: context.tr('Email'),
                  hintText: 'ban@example.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (value) => (value ?? '').length < 6
                    ? context.tr('Mật khẩu cần ít nhất 6 ký tự')
                    : null,
                decoration: InputDecoration(
                  labelText: context.tr('Mật khẩu'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                validator: (value) => value != _passwordController.text
                    ? context.tr('Mật khẩu xác nhận chưa khớp')
                    : null,
                decoration: InputDecoration(
                  labelText: context.tr('Xác nhận mật khẩu'),
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      TextSpan(text: context.tr('Tôi đồng ý với ')),
                      TextSpan(
                        text: context.tr(
                          'Điều khoản sử dụng và Chính sách riêng tư',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                text: 'Tạo tài khoản',
                icon: Icons.arrow_forward_rounded,
                isLoading: auth.isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
