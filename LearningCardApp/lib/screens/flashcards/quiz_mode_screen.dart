import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';

class QuizModeScreen extends StatefulWidget {
  final List<Flashcard> cards;
  final int setId;
  final String title;

  const QuizModeScreen({super.key, required this.cards, required this.setId, required this.title});

  @override
  State<QuizModeScreen> createState() => _QuizModeScreenState();
}

class _QuizModeScreenState extends State<QuizModeScreen> {
  int index = 0;
  List<bool> userResults = [];
  List<String>? currentOptions;

  @override
  void initState() {
    super.initState();
    context.read<FlashcardProvider>().resetQuizStats();
  }

  void _generateOptions(List<Flashcard> cards, int currentIndex) {
    final current = cards[currentIndex];
    final wrongOptions = cards.where((c) => c.id != current.id).toList()..shuffle();
    final options = ([current.back, ...wrongOptions.take(3).map((c) => c.back)]..shuffle());
    currentOptions = options.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final cards = widget.cards;
    if (currentOptions == null) _generateOptions(cards, index);
    final current = cards[index];
    final labels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // 1. THANH TIẾN ĐỘ CỐ ĐỊNH Ở DƯỚI
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: List.generate(cards.length, (i) {
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  color: i <= index ? const Color(0xFF7C6CFF) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
      // 2. NỘI DUNG CHÍNH (Câu hỏi cố định, đáp án cuộn)
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Câu hỏi (Cố định ở trên)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6CFF),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Text(current.front, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),

            // Danh sách đáp án (Chỉ phần này cuộn)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () async {
                            bool isCorrect = currentOptions![i] == current.back;
                            userResults.add(isCorrect);
                            provider.markAnswer(isCorrect);
                            if (index + 1 < cards.length) {
                              setState(() { index++; currentOptions = null; });
                            } else {
                              await _showResults(provider);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 1.5)),
                            child: Row(
                              children: [
                                Text("${labels[i]}.", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C6CFF), fontSize: 16)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(currentOptions![i], style: const TextStyle(fontSize: 15, color: Color(0xFF4A4A4A)))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResults(FlashcardProvider provider) async {
    await provider.saveProgress(
      setId: widget.setId,
      totalCards: widget.cards.length,
      learnedCards: widget.cards.length,
      correctAnswers: provider.correctAnswers,
      wrongAnswers: provider.wrongAnswers,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 50, color: Color(0xFF7C6CFF)),
              const SizedBox(height: 10),
              const Text('Kết quả hoàn thành', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: provider.cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: userResults[i] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(userResults[i] ? Icons.check_circle : Icons.cancel,
                            color: userResults[i] ? Colors.green : Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Câu hỏi: ${provider.cards[i].front}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Đáp án: ${provider.cards[i].back}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6CFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}