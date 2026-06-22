import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: const CircleAvatar(radius: 28, child: Icon(Icons.person)),
              title: Text(user?.name ?? 'Guest'),
              subtitle: Text(user?.email ?? 'Login to sync your data'),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(20),
              title: Text('Workflow App'),
              subtitle: Text('Splash -> Login/Register -> Home -> Flashcards/Notes/AI -> Save progress to backend.'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
            child: const Text('Dang xuat'),
          ),
        ],
      ),
    );
  }
}