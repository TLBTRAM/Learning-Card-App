import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/flashcard_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const SmartFlashcardNotesApp());
}

class SmartFlashcardNotesApp extends StatelessWidget {
  const SmartFlashcardNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Flashcard Notes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}