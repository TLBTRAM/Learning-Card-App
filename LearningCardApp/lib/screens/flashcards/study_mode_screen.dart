import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import '../../models/flashcard_model.dart';

class StudyModeScreen extends StatefulWidget {
  final List<Flashcard> cards;
  const StudyModeScreen({super.key, required this.cards});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  int _currentIndex = 0;
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  void _changeCard(int delta) {
    setState(() {
      _currentIndex = (_currentIndex + delta).clamp(0, widget.cards.length - 1);
      // Tự động lật về mặt trước khi chuyển card
      if (cardKey.currentState != null && !cardKey.currentState!.isFront) {
        cardKey.currentState!.toggleCard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Study Mode", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text("Card ${_currentIndex + 1} / ${widget.cards.length}",
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: FlipCard(
              key: cardKey,
              front: _buildCard("Question", card.front, true),
              back: _buildCard("Answer", card.back, false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex > 0 ? () => _changeCard(-1) : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: const BorderSide(color: Color(0xFF7C6CFF)),
                    ),
                    child: const Text("Prev", style: TextStyle(color: Color(0xFF7C6CFF), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentIndex < widget.cards.length - 1 ? () => _changeCard(1) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6CFF),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(String label, String content, bool isQuestion) {
    final bgColor = isQuestion ? Colors.white : const Color(0xFF7C6CFF);
    final textColor = isQuestion ? const Color(0xFF7C6CFF) : Colors.white;
    final borderColor = isQuestion ? const Color(0xFF7C6CFF) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      height: 450, // Chiều cao cố định
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: isQuestion ? Border.all(color: borderColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: textColor,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: isQuestion ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}