import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate format trước khi gửi
    if (!RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email phải có đuôi @gmail.com')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu phải tối thiểu 6 chữ số')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email, password);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      // Hiển thị lỗi từ database (Email không tồn tại, sai mật khẩu, v.v.)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Có lỗi xảy ra')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFECE9FF), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.style_rounded, size: 42, color: Color(0xFF7C6CFF))),
              const SizedBox(height: 24),
              const Text('Chào mừng trở lại', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Đăng nhập để tiếp tục học flashcard, ghi chú và hỏi AI.'),
              const SizedBox(height: 28),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', hintText: 'ví dụ: diachiemail@gmail.com')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', hintText: 'Tối thiểu 6 chữ số')),
              const SizedBox(height: 20),
              AppButton(text: 'Đăng nhập', isLoading: auth.isLoading, onPressed: _login),
              const SizedBox(height: 16),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      const TextSpan(text: 'Chưa có tài khoản? '),
                      TextSpan(
                        text: 'Đăng ký',
                        style: const TextStyle(color: Color(0xFF7C6CFF), fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}