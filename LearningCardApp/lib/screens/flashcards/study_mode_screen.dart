import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/flashcard_provider.dart';

class StudyModeScreen extends StatefulWidget {
  final int setId;
  final String title;

  const StudyModeScreen({super.key, required this.setId, required this.title});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadCards(widget.setId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (provider.cards.isEmpty) return Scaffold(appBar: AppBar(title: Text(widget.title)), body: const Center(child: Text('Khong co card de hoc.')));
    final card = provider.cards[index];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Card ${index + 1}/${provider.cards.length}'),
            const SizedBox(height: 24),
            Expanded(
              child: FlipCard(
                front: _CardFace(text: card.front, label: 'Front', color: const Color(0xFFECE9FF)),
                back: _CardFace(text: card.back, label: 'Back', color: const Color(0xFFFFF0E3)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: index == 0 ? null : () => setState(() => index--), child: const Text('Prev'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (index + 1 < provider.cards.length) {
                        setState(() => index++);
                      } else {
                        await provider.saveProgress(widget.setId, learnedCards: provider.cards.length);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Da luu tien do hoc')));
                      }
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String label;
  final Color color;

  const _CardFace({required this.text, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28)),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
          const Spacer(),
        ],
      ),
    );
  }
}