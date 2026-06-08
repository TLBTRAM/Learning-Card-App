import 'package:flutter/material.dart';
import '../models/study_set.dart';

class QuizScreen extends StatefulWidget {
  final StudySet studySet;

  const QuizScreen({
    super.key,
    required this.studySet,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String selectedAnswer = '';

  List<String> getOptions() {
    final correctAnswer = widget.studySet.cards[currentIndex].definition;

    final allAnswers = widget.studySet.cards
        .map((card) => card.definition)
        .toList();

    allAnswers.shuffle();

    final options = allAnswers.take(4).toList();

    if (!options.contains(correctAnswer)) {
      options[0] = correctAnswer;
    }

    options.shuffle();

    return options;
  }

  void checkAnswer(String answer) {
    if (answered) return;

    final correctAnswer = widget.studySet.cards[currentIndex].definition;

    setState(() {
      selectedAnswer = answer;
      answered = true;

      if (answer == correctAnswer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentIndex < widget.studySet.cards.length - 1) {
      setState(() {
        currentIndex++;
        answered = false;
        selectedAnswer = '';
      });
    } else {
      showResultDialog();
    }
  }

  void showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Result'),
          content: Text(
            'Score: $score / ${widget.studySet.cards.length}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to Flashcards'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.studySet.cards[currentIndex];
    final correctAnswer = card.definition;
    final options = getOptions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Mode'),
        backgroundColor: const Color(0xffF7F3EA),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${currentIndex + 1} / ${widget.studySet.cards.length}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text(
                    'Từ này có nghĩa là gì?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    card.term,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    card.hiragana,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ...options.map((option) {
              Color buttonColor = Colors.white;
              Color textColor = Colors.black;

              if (answered) {
                if (option == correctAnswer) {
                  buttonColor = const Color(0xff5BA199);
                  textColor = Colors.white;
                } else if (option == selectedAnswer) {
                  buttonColor = Colors.red.shade300;
                  textColor = Colors.white;
                }
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => checkAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: textColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: answered ? nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  currentIndex == widget.studySet.cards.length - 1
                      ? 'Finish'
                      : 'Next Question',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}