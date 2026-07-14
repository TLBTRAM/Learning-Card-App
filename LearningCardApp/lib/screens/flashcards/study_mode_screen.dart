import 'dart:async';

import 'package:flip_card/flip_card.dart';
import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/state_panel.dart';

class StudyModeScreen extends StatefulWidget {
  final List<Flashcard> cards;

  const StudyModeScreen({super.key, required this.cards});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  int _currentIndex = 0;
  int _remembered = 0;
  int _learning = 0;
  int _forgotten = 0;
  GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();

  void _changeCard(int delta) {
    final next = _currentIndex + delta;
    if (next < 0 || next >= widget.cards.length) return;
    setState(() {
      _currentIndex = next;
      _cardKey = GlobalKey<FlipCardState>();
    });
  }

  void _rate(_MemoryRating rating) {
    switch (rating) {
      case _MemoryRating.forgotten:
        _forgotten++;
      case _MemoryRating.learning:
        _learning++;
      case _MemoryRating.remembered:
        _remembered++;
    }
    unawaited(
      context
          .read<FlashcardProvider>()
          .saveCardReview(
            cardId: widget.cards[_currentIndex].id,
            rating: rating.name,
          )
          .catchError((_) {}),
    );
    if (_currentIndex < widget.cards.length - 1) {
      _changeCard(1);
    } else {
      _showCompleted();
    }
  }

  Future<void> _showCompleted() async {
    final setIds = widget.cards.map((card) => card.setId).toSet();
    if (setIds.length == 1) {
      unawaited(
        context
            .read<FlashcardProvider>()
            .saveProgress(
              setId: setIds.first,
              totalCards: widget.cards.length,
              learnedCards: widget.cards.length,
              correctAnswers: _remembered,
              wrongAnswers: _forgotten,
            )
            .catchError((_) {}),
      );
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 66,
          height: 66,
          decoration: const BoxDecoration(
            color: AppColors.brassSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.warning,
            size: 30,
          ),
        ),
        title: const Text('Hoàn thành phiên học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bạn vừa đi hết bộ thẻ. Những thẻ chưa nhớ sẽ được ưu tiên ở lần ôn tiếp theo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _ResultStat(label: 'Chưa nhớ', value: _forgotten),
                _ResultStat(label: 'Hơi nhớ', value: _learning),
                _ResultStat(label: 'Đã nhớ', value: _remembered),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _currentIndex = 0;
                _cardKey = GlobalKey<FlipCardState>();
              });
            },
            child: const Text('Học lại'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const Scaffold(
        body: StatePanel(
          icon: Icons.style_outlined,
          title: 'Chưa có thẻ để học',
          message: 'Hãy thêm nội dung vào bộ flashcard rồi quay lại.',
        ),
      );
    }
    final card = widget.cards[_currentIndex];
    final progress = (_currentIndex + 1) / widget.cards.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chế độ học'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                '${_currentIndex + 1}/${widget.cards.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: progress, minHeight: 7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chạm để lật · Vuốt để chuyển thẻ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -180) _changeCard(1);
                  if (velocity > 180) _changeCard(-1);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: FlipCard(
                    key: _cardKey,
                    direction: FlipDirection.HORIZONTAL,
                    speed: 420,
                    front: _StudyCard(
                      label: 'THUẬT NGỮ',
                      content: card.front,
                      isFront: true,
                      onPronounce: () => UiFeedback.showSuccess(
                        context,
                        'Đã gửi yêu cầu phát âm “${card.front}”.',
                      ),
                    ),
                    back: _StudyCard(
                      label: 'ĐỊNH NGHĨA',
                      content: card.back,
                      example: card.example,
                      isFront: false,
                      onPronounce: () => UiFeedback.showSuccess(
                        context,
                        'Đã gửi yêu cầu phát âm nội dung thẻ.',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: _MemoryButton(
                      label: 'Chưa nhớ',
                      icon: Icons.refresh_rounded,
                      color: AppColors.error,
                      onTap: () => _rate(_MemoryRating.forgotten),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MemoryButton(
                      label: 'Hơi nhớ',
                      icon: Icons.psychology_alt_outlined,
                      color: AppColors.warning,
                      onTap: () => _rate(_MemoryRating.learning),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MemoryButton(
                      label: 'Đã nhớ',
                      icon: Icons.check_rounded,
                      color: AppColors.success,
                      onTap: () => _rate(_MemoryRating.remembered),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  final String label;
  final String content;
  final String? example;
  final bool isFront;
  final VoidCallback onPronounce;

  const _StudyCard({
    required this.label,
    required this.content,
    required this.isFront,
    required this.onPronounce,
    this.example,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isFront
        ? (isDark ? AppColors.darkSurface : AppColors.ivory)
        : AppColors.navy;
    final foreground = isFront
        ? Theme.of(context).colorScheme.onSurface
        : AppColors.ivory;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isFront
              ? Theme.of(context).colorScheme.outlineVariant
              : AppColors.navyLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isFront ? AppColors.lavenderSoft : AppColors.navyLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isFront ? AppColors.lavenderDeep : AppColors.brass,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.tr('Phát âm'),
                onPressed: onPronounce,
                color: foreground,
                icon: const Icon(Icons.volume_up_outlined),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      content,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: foreground,
                            fontSize: isFront ? 36 : 31,
                          ),
                    ),
                    if (!isFront && (example ?? '').isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.navyLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Ví dụ: ${example!}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.ivory.withValues(alpha: .76),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Text(
            isFront
                ? 'Chạm vào thẻ để xem đáp án'
                : 'Chạm để quay lại thuật ngữ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: .55),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MemoryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final int value;

  const _ResultStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

enum _MemoryRating { forgotten, learning, remembered }
