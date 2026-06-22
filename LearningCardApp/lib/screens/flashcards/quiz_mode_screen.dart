import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/flashcard_provider.dart';

class QuizModeScreen extends StatefulWidget {
  final int setId;
  final String title;

  const QuizModeScreen({super.key, required this.setId, required this.title});

  @override
  State<QuizModeScreen> createState() => _QuizModeScreenState();
}

class _QuizModeScreenState extends State<QuizModeScreen> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>()
        ..resetQuizStats()
        ..loadCards(widget.setId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (provider.cards.length < 2) return Scaffold(appBar: AppBar(title: Text(widget.title)), body: const Center(child: Text('Can it nhat 2 card de lam quiz.')));

    final current = provider.cards[index];
    final wrongOptions = provider.cards.where((item) => item.id != current.id).map((item) => item.back).take(3).toList();
    final options = ([current.back, ...wrongOptions]..shuffle(Random()));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cau hoi ${index + 1}/${provider.cards.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(current.front, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 20),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () async {
                    provider.markAnswer(option == current.back);
                    if (index + 1 < provider.cards.length) {
                      setState(() => index++);
                    } else {
                      await provider.saveProgress(widget.setId, learnedCards: provider.cards.length);
                      if (!context.mounted) return;
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Quiz Finished'),
                          content: Text('Dung: ${provider.correctAnswers}\nSai: ${provider.wrongAnswers}'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  child: Text(option),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}