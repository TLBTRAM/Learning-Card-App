import 'dart:math' as math;

import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../models/dashboard_model.dart';
import '../../models/review_dashboard_model.dart';
import '../../providers/review_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_panel.dart';
import '../flashcards/study_mode_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String _filter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReviewProvider>().loadReview(),
    );
  }

  void _startReview(List<ReviewCardItem> items) {
    if (items.isEmpty) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            StudyModeScreen(cards: items.map((item) => item.card).toList()),
      ),
    ).then((_) {
      if (mounted) context.read<ReviewProvider>().loadReview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final data = provider.data;
    final filtered = _filter == 'Tất cả'
        ? data.cards
        : data.cards.where((item) => item.category == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ôn tập'),
            Text(
              'Dựa trên lịch sử học thật của bạn',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Tải lại',
            onPressed: provider.loadReview,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _body(provider, data, filtered),
    );
  }

  Widget _body(
    ReviewProvider provider,
    ReviewDashboardData data,
    List<ReviewCardItem> filtered,
  ) {
    if (provider.isLoading && data.cards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && data.cards.isEmpty) {
      return StatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'Chưa tải được lịch ôn',
        message: 'Hãy kiểm tra backend và thử lại.',
        actionLabel: 'Thử lại',
        onAction: provider.loadReview,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadReview,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
        children: [
          PremiumSurface(
            color: AppColors.navy,
            border: Border.all(color: Colors.transparent),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐẾN HẠN THỰC TẾ',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.brass,
                              letterSpacing: .8,
                            ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        data.dueCount == 0
                            ? 'Chưa có thẻ cần ôn'
                            : '${data.dueCount} thẻ cần ôn',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: AppColors.ivory),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data.dueCount == 0
                            ? 'Hãy học một bộ thẻ để tạo lịch ôn'
                            : 'Khoảng ${data.estimatedMinutes} phút · Chuỗi ${data.studyStreak} ngày',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ivory.withValues(alpha: .65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: data.dueCount == 0
                        ? AppColors.navyLight
                        : AppColors.brass,
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(54, 54),
                  ),
                  onPressed: data.dueCount == 0
                      ? null
                      : () => _startReview(
                          filtered.isEmpty ? data.cards : filtered,
                        ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 29),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Hoạt động 7 ngày',
            subtitle: 'Số thẻ đã học theo từng ngày',
          ),
          const SizedBox(height: 14),
          PremiumSurface(
            child: SizedBox(
              height: 156,
              child: data.weeklyActivity.isEmpty
                  ? const Center(child: Text('Chưa có phiên học nào'))
                  : CustomPaint(
                      painter: _WeeklyProgressPainter(
                        activity: data.weeklyActivity,
                        lineColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.lavender
                            : AppColors.lavenderDeep,
                        gridColor: Theme.of(context).colorScheme.outlineVariant,
                        textColor: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: '14 ngày gần nhất',
            subtitle: 'Ngày có học được đánh dấu trực tiếp từ lịch sử phiên',
          ),
          const SizedBox(height: 14),
          _StudyCalendar(studyDates: data.studyDates),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Thẻ cần ưu tiên',
            subtitle: '${filtered.length} kết quả theo bộ lọc',
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tất cả', 'Khó', 'Chưa nhớ', 'Sắp đến hạn']
                  .map(
                    (label) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: _filter == label,
                        label: Text(label),
                        onSelected: (_) => setState(() => _filter = label),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const SizedBox(
              height: 220,
              child: StatePanel(
                icon: Icons.task_alt_rounded,
                title: 'Không có thẻ trong nhóm này',
                message: 'Lịch ôn sẽ tự cập nhật sau mỗi lần bạn đánh giá thẻ.',
              ),
            )
          else
            ...filtered.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewTile(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewCardItem item;

  const _ReviewTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = switch (item.category) {
      'Khó' => AppColors.warning,
      'Sắp đến hạn' => AppColors.lavenderDeep,
      _ => AppColors.error,
    };
    return PremiumSurface(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.event_repeat_rounded, color: color, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.card.front,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.setTitle} · Tạo bởi ${item.ownerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.category,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyCalendar extends StatelessWidget {
  final Set<DateTime> studyDates;

  const _StudyCalendar({required this.studyDates});

  bool _isStudied(DateTime date) => studyDates.any(
    (item) =>
        item.year == date.year &&
        item.month == date.month &&
        item.day == date.day,
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(
      14,
      (index) => DateTime(now.year, now.month, now.day - 13 + index),
    );
    return PremiumSurface(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: .9,
        ),
        itemCount: days.length,
        itemBuilder: (_, index) {
          final date = days[index];
          final active = _isStudied(date);
          final today =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.success.withValues(alpha: .14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: today
                    ? AppColors.brass
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Icon(
                  active ? Icons.check_rounded : Icons.remove_rounded,
                  size: 12,
                  color: active
                      ? AppColors.success
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeeklyProgressPainter extends CustomPainter {
  final List<WeeklyStudyPoint> activity;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _WeeklyProgressPainter({
    required this.activity,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottom = 27.0;
    const top = 10.0;
    final chartHeight = size.height - bottom - top;
    final maxValue = math.max(
      1,
      activity.fold<int>(0, (max, item) => math.max(max, item.learnedCards)),
    );
    final step = size.width / math.max(activity.length - 1, 1);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      final y = top + (chartHeight * index / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path();
    for (var index = 0; index < activity.length; index++) {
      final ratio = activity[index].learnedCards / maxValue;
      final point = Offset(index * step, top + chartHeight * (1 - ratio));
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    const labels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    for (var index = 0; index < activity.length; index++) {
      final ratio = activity[index].learnedCards / maxValue;
      final point = Offset(index * step, top + chartHeight * (1 - ratio));
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
      final painter = TextPainter(
        text: TextSpan(
          text: labels[activity[index].date.weekday % 7],
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(point.dx - painter.width / 2, size.height - painter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyProgressPainter oldDelegate) =>
      oldDelegate.activity != activity || oldDelegate.lineColor != lineColor;
}
