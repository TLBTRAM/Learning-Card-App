import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard_set_model.dart';
import '../../providers/flashcard_provider.dart';
import 'edit_flashcard_screen.dart';
import 'study_mode_screen.dart';
import 'quiz_mode_screen.dart';
import 'create_flashcard_screen.dart';

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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text(widget.flashcardSet.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), backgroundColor: Colors.white, elevation: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C6CFF),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateFlashcardScreen(setId: widget.flashcardSet.id))).then((_) => provider.loadCards(widget.flashcardSet.id)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: _buildModeButton(context, 'Study', Icons.school, Colors.white, const Color(0xFF7C6CFF), onTap: () {
                  if (provider.cards.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => StudyModeScreen(cards: provider.cards)));
                })),
                const SizedBox(width: 15),
                Expanded(child: _buildModeButton(context, 'Quiz', Icons.quiz, const Color(0xFF7C6CFF), Colors.white, onTap: () {
                  if (provider.cards.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => QuizModeScreen(
                      cards: provider.cards,
                      setId: widget.flashcardSet.id,
                      title: widget.flashcardSet.title
                  )));
                })),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: provider.cards.length,
              itemBuilder: (_, index) {
                final card = provider.cards[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel("Q:", const Color(0xFF7C6CFF)), Text(card.front, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10),
                      _buildLabel("A:", Colors.green), Text(card.back, style: TextStyle(color: Colors.grey.shade700)),
                    ])),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditFlashcardScreen(setId: widget.flashcardSet.id, card: card)))),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => provider.deleteCard(widget.flashcardSet.id, card.id)),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)), child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)));

  Widget _buildModeButton(context, title, icon, bgColor, textColor, {onTap}) => ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFF7C6CFF)))), onPressed: onTap, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20, color: textColor), const SizedBox(width: 8), Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))]));
}