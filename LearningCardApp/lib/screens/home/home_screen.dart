import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/gradient_card.dart';
import '../ai/ai_chat_screen.dart';
import '../flashcards/flashcard_sets_screen.dart';
import '../notes/handwriting_note_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  static bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    if (!_hasShownWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeMessage();
      });
    }
  }

  @override
  void dispose() {
    _hasShownWelcome = false;
    super.dispose();
  }

  void _showWelcomeMessage() {
    final user = context.read<AuthProvider>().user;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Xin chào ${user?.name ?? 'Bạn'}!'),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF7C6CFF),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
    _hasShownWelcome = true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(onChangeTab: (index) => setState(() => selectedIndex = index)),
      const FlashcardSetsScreen(),
      const HandwritingNoteScreen(),
      const AiChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.style_outlined), label: 'Cards'),
          NavigationDestination(icon: Icon(Icons.draw_outlined), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  final ValueChanged<int> onChangeTab;

  const DashboardView({super.key, required this.onChangeTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GradientCard(
            colors: const [Color(0xFF7C6CFF), Color(0xFFA394FF)],
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Học thông minh hơn mỗi ngày', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Flashcard, ghi chú viết tay và AI chatbot trong cùng một app.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _QuickCard(title: 'Bộ thẻ Flashcard', subtitle: 'Tạo bộ thẻ và học nhanh', icon: Icons.collections_bookmark, onTap: () => onChangeTab(1)),
          _QuickCard(title: 'Ghi chú viết tay', subtitle: 'Viết tay như vở ghi chú', icon: Icons.draw, onTap: () => onChangeTab(2)),
          _QuickCard(title: 'AI Chatbox', subtitle: 'Hỏi bài và tạo flashcard', icon: Icons.smart_toy, onTap: () => onChangeTab(3)),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: const Color(0xFFECE9FF), child: Icon(icon, color: const Color(0xFF7C6CFF))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}