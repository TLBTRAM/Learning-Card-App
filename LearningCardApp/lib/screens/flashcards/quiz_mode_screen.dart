import 'dart:async';

import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/state_panel.dart';

class QuizModeScreen extends StatefulWidget {
  final List<Flashcard> cards;
  final int setId;
  final String title;

  const QuizModeScreen({
    super.key,
    required this.cards,
    required this.setId,
    required this.title,
  });

  @override
  State<QuizModeScreen> createState() => _QuizModeScreenState();
}

class _QuizModeScreenState extends State<QuizModeScreen> {
  int _index = 0;
  int? _selectedIndex;
  late List<String> _options;
  final List<bool> _results = [];
  bool _timerEnabled = false;
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<FlashcardProvider>().resetQuizStats();
    if (widget.cards.isNotEmpty) _options = _makeOptions(widget.cards.first);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String> _makeOptions(Flashcard card) {
    final explicit = [
      card.optionA,
      card.optionB,
      card.optionC,
      card.optionD,
    ].where((option) => option.trim().isNotEmpty).toList();
    if (explicit.length == 4) return explicit;

    final options = <String>{card.back};
    final otherAnswers =
        widget.cards
            .where((item) => item.id != card.id)
            .map((item) => item.back)
            .where((value) => value.trim().isNotEmpty)
            .toList()
          ..shuffle();
    options.addAll(otherAnswers.take(3));
    const fallbacks = [
      'Một khái niệm khác',
      'Không có đáp án phù hợp',
      'Cần thêm dữ kiện',
    ];
    for (final fallback in fallbacks) {
      if (options.length >= 4) break;
      options.add(fallback);
    }
    final result = options.take(4).toList()..shuffle();
    return result;
  }

  void _toggleTimer() {
    setState(() => _timerEnabled = !_timerEnabled);
    if (_timerEnabled) {
      _startTimer();
    } else {
      _timer?.cancel();
      setState(() => _seconds = 30);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _selectedIndex != null) {
        timer.cancel();
        return;
      }
      if (_seconds <= 1) {
        timer.cancel();
        _answer(-1);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _answer(int selected) {
    if (_selectedIndex != null) return;
    _timer?.cancel();
    final correct =
        selected >= 0 && _options[selected] == widget.cards[_index].back;
    setState(() => _selectedIndex = selected);
    _results.add(correct);
    final provider = context.read<FlashcardProvider>();
    provider.markAnswer(correct);
    unawaited(
      provider
          .saveCardReview(
            cardId: widget.cards[_index].id,
            rating: correct ? 'remembered' : 'forgotten',
          )
          .catchError((_) {}),
    );
  }

  Future<void> _next() async {
    if (_index < widget.cards.length - 1) {
      setState(() {
        _index++;
        _selectedIndex = null;
        _options = _makeOptions(widget.cards[_index]);
        _seconds = 30;
      });
      if (_timerEnabled) _startTimer();
    } else {
      await _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final provider = context.read<FlashcardProvider>();
    try {
      await provider.saveProgress(
        setId: widget.setId,
        totalCards: widget.cards.length,
        learnedCards: widget.cards.length,
        correctAnswers: provider.correctAnswers,
        wrongAnswers: provider.wrongAnswers,
      );
    } catch (_) {
      // Kết quả vẫn được hiển thị khi đồng bộ tiến độ tạm thời thất bại.
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final score = provider.correctAnswers;
        final percent = (score / widget.cards.length * 100).round();
        return AlertDialog(
          icon: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.brassSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.warning,
              size: 32,
            ),
          ),
          title: const Text('Hoàn thành bài quiz'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  '$score/${widget.cards.length} câu trả lời đúng',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.cards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (_results[index]
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _results[index]
                                ? Icons.check_circle_outline_rounded
                                : Icons.cancel_outlined,
                            color: _results[index]
                                ? AppColors.success
                                : AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.cards[index].front,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _index = 0;
                  _selectedIndex = null;
                  _results.clear();
                  _options = _makeOptions(widget.cards.first);
                  _seconds = 30;
                });
                provider.resetQuizStats();
                if (_timerEnabled) _startTimer();
              },
              child: const Text('Làm lại'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Hoàn tất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const Scaffold(
        body: StatePanel(
          icon: Icons.quiz_outlined,
          title: 'Chưa thể tạo bài quiz',
          message: 'Bộ flashcard cần ít nhất một thẻ.',
        ),
      );
    }
    final current = widget.cards[_index];
    final answered = _selectedIndex != null;
    final progress = (_index + 1) / widget.cards.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: context.tr(_timerEnabled ? 'Tắt đồng hồ' : 'Bật đồng hồ'),
            onPressed: _toggleTimer,
            icon: Icon(
              _timerEnabled ? Icons.timer_rounded : Icons.timer_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: answered
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: AppButton(
                  text: _index == widget.cards.length - 1
                      ? 'Xem kết quả'
                      : 'Câu tiếp theo',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress, minHeight: 7),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${_index + 1}/${widget.cards.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (_timerEnabled) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (_seconds <= 10
                                ? AppColors.error
                                : AppColors.lavenderDeep)
                            .withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_seconds}s',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _seconds <= 10
                          ? AppColors.error
                          : AppColors.lavenderDeep,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          PremiumSurface(
            color: AppColors.navy,
            border: Border.all(color: Colors.transparent),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHỌN ĐỊNH NGHĨA ĐÚNG',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.brass,
                    letterSpacing: .9,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  current.front,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppColors.ivory),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            _options.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnswerOption(
                label: String.fromCharCode(65 + index),
                text: _options[index],
                selected: _selectedIndex == index,
                isCorrect: answered && _options[index] == current.back,
                isWrong:
                    answered &&
                    _selectedIndex == index &&
                    _options[index] != current.back,
                disabled: answered,
                onTap: () => _answer(index),
              ),
            ),
          ),
          if (answered) ...[
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _ExplanationPanel(
                key: ValueKey(_index),
                correct:
                    _selectedIndex != -1 &&
                    _selectedIndex != null &&
                    _options[_selectedIndex!] == current.back,
                answer: current.back,
                explanation: current.example,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final bool isCorrect;
  final bool isWrong;
  final bool disabled;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.label,
    required this.text,
    required this.selected,
    required this.isCorrect,
    required this.isWrong,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect
        ? AppColors.success
        : isWrong
        ? AppColors.error
        : selected
        ? AppColors.lavenderDeep
        : Theme.of(context).colorScheme.outline;
    return Material(
      color: (isCorrect || isWrong)
          ? color.withValues(alpha: .09)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color,
              width: selected || isCorrect ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(child: Text(text)),
              if (isCorrect)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 21,
                )
              else if (isWrong)
                const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.error,
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationPanel extends StatelessWidget {
  final bool correct;
  final String answer;
  final String explanation;

  const _ExplanationPanel({
    super.key,
    required this.correct,
    required this.answer,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_rounded : Icons.lightbulb_outline_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Chính xác!' : 'Gần đúng rồi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Đáp án: $answer'),
          const SizedBox(height: 5),
          Text(
            explanation.isEmpty
                ? 'Hãy liên hệ thuật ngữ với định nghĩa này để ghi nhớ lâu hơn.'
                : explanation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
