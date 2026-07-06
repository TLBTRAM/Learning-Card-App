import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/flashcard_set_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/flashcard_item.dart';
import 'create_flashcard_screen.dart';
import 'quiz_mode_screen.dart';
import 'study_mode_screen.dart';

class FlashcardDetailScreen extends StatefulWidget {
  final FlashcardSet flashcardSet;

  const FlashcardDetailScreen({super.key, required this.flashcardSet});

  @override
  State<FlashcardDetailScreen> createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadCards(widget.flashcardSet.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.flashcardSet.title)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateFlashcardScreen(setId: widget.flashcardSet.id))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: provider.cards.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudyModeScreen(setId: widget.flashcardSet.id, title: widget.flashcardSet.title))), child: const Text('Study Mode'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: provider.cards.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizModeScreen(setId: widget.flashcardSet.id, title: widget.flashcardSet.title))), child: const Text('Quiz Mode'))),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.cards.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Set này chưa có card.')))
          else
            ...provider.cards.map((card) => FlashcardItem(card: card, onDelete: () => context.read<FlashcardProvider>().deleteCard(widget.flashcardSet.id, card.id))),
        ],
      ),
    );
  }
}