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
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Login failed')));
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: const Color(0xFFECE9FF), borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.style_rounded, size: 42, color: Color(0xFF7C6CFF)),
              ),
              const SizedBox(height: 24),
              const Text('Chao mung tro lai', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Dang nhap de tiep tuc hoc flashcard, ghi chu va hoi AI.'),
              const SizedBox(height: 28),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 20),
              AppButton(text: 'Dang nhap', isLoading: auth.isLoading, onPressed: _login),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Chua co tai khoan? Dang ky'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}