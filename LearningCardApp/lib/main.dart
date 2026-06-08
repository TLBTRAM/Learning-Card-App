import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MemoCardApp());
}

class MemoCardApp extends StatelessWidget {
  const MemoCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KotobaBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffF7F3EA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5BA199),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}