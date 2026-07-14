import 'dart:math' as math;

import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';

class HandwritingCanvasWidget extends StatefulWidget {
  final NoteModel? noteToLoad;
  final VoidCallback onClearSelection;
  final bool readOnly;

  const HandwritingCanvasWidget({
    super.key,
    this.noteToLoad,
    required this.onClearSelection,
    this.readOnly = false,
  });

  @override
  State<HandwritingCanvasWidget> createState() =>
      _HandwritingCanvasWidgetState();
}

class _HandwritingCanvasWidgetState extends State<HandwritingCanvasWidget> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<_StrokePath> _strokes = [];
  final List<_StrokePath> _redoStack = [];
  _StrokePath? _currentStroke;
  Color _selectedColor = AppColors.ink;
  double _strokeWidth = 3;
  bool _isEraser = false;
  bool _isSaving = false;
  int? _editingNoteId;

  @override
  void initState() {
    super.initState();
    if (widget.noteToLoad != null) _loadNote(widget.noteToLoad!);
  }

  @override
  void didUpdateWidget(covariant HandwritingCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.noteToLoad != null &&
        widget.noteToLoad?.id != oldWidget.noteToLoad?.id) {
      _loadNote(widget.noteToLoad!);
    } else if (widget.noteToLoad == null && oldWidget.noteToLoad != null) {
      _newPage();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _newPage() {
    _titleController.clear();
    _contentController.clear();
    _editingNoteId = null;
    _strokes.clear();
    _redoStack.clear();
    if (mounted) setState(() {});
  }

  void _loadNote(NoteModel note) {
    _titleController.text = note.title;
    _contentController.text = note.contentText;
    _editingNoteId = note.id;
    _strokes
      ..clear()
      ..addAll(
        note.drawingData.map((item) {
          final map = Map<String, dynamic>.from(item);
          final rawPoints = map['points'] as List<dynamic>? ?? const [];
          final points = rawPoints.map((point) {
            final value = Map<String, dynamic>.from(point);
            return Offset(
              (value['x'] as num? ?? 0).toDouble(),
              (value['y'] as num? ?? 0).toDouble(),
            );
          }).toList();
          return _StrokePath(
            points: points,
            color: _parseColor(map['color']?.toString()),
            strokeWidth: (map['strokeWidth'] as num? ?? 3).toDouble(),
          );
        }),
      );
    _redoStack.clear();
    if (mounted) setState(() {});
  }

  Color _parseColor(String? value) {
    try {
      return Color(
        int.parse((value ?? '#202A3B').replaceFirst('#', 'FF'), radix: 16),
      );
    } catch (_) {
      return AppColors.ink;
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _redoStack.add(_strokes.removeLast()));
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() => _strokes.add(_redoStack.removeLast()));
  }

  void _clearCanvas() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.addAll(_strokes.reversed);
      _strokes.clear();
    });
  }

  void _eraseAt(Offset point) {
    const threshold = 18.0;
    setState(() {
      _strokes.removeWhere(
        (stroke) =>
            stroke.points.any((value) => (value - point).distance <= threshold),
      );
    });
  }

  Future<void> _saveNote() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final provider = context.read<NoteProvider>();
    final note = await provider.saveNote(
      id: _editingNoteId,
      title: _titleController.text.trim().isEmpty
          ? 'Ghi chú chưa đặt tên'
          : _titleController.text.trim(),
      contentText: _contentController.text.trim(),
      drawingData: _strokes
          .map(
            (stroke) => {
              'points': stroke.points
                  .map((point) => {'x': point.dx, 'y': point.dy})
                  .toList(),
              'color':
                  '#${stroke.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              'strokeWidth': stroke.strokeWidth,
            },
          )
          .toList(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (note != null) {
      UiFeedback.showSuccess(context, 'Đã lưu vào sổ tay.');
      widget.onClearSelection();
      _newPage();
    } else {
      UiFeedback.showError(
        context,
        provider.errorMessage,
        fallback: 'Chưa thể lưu ghi chú. Vui lòng thử lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    readOnly: widget.readOnly,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      hintText: context.tr('Tiêu đề ghi chú'),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: context.tr('Lưu ghi chú'),
                  onPressed: _isSaving || widget.readOnly ? null : _saveNote,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _contentController,
              readOnly: widget.readOnly,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: context.tr('Thêm mô tả hoặc ghi chú dạng text...'),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.readOnly)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.lavenderDeep,
                  ),
                  SizedBox(width: 8),
                  Text('Ghi chú được chia sẻ ở chế độ chỉ đọc'),
                ],
              ),
            )
          else
            SizedBox(
              height: 54,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _ToolButton(
                    icon: Icons.edit_rounded,
                    label: 'Bút',
                    selected: !_isEraser,
                    onTap: () => setState(() => _isEraser = false),
                  ),
                  const SizedBox(width: 8),
                  _ToolButton(
                    icon: Icons.auto_fix_normal_rounded,
                    label: 'Tẩy',
                    selected: _isEraser,
                    onTap: () => setState(() => _isEraser = true),
                  ),
                  const SizedBox(width: 12),
                  ...[
                    AppColors.ink,
                    AppColors.lavenderDeep,
                    AppColors.error,
                    AppColors.success,
                    AppColors.warning,
                  ].map(
                    (color) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ColorDot(
                        color: color,
                        selected: !_isEraser && _selectedColor == color,
                        onTap: () => setState(() {
                          _selectedColor = color;
                          _isEraser = false;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 110,
                    child: Slider(
                      value: _strokeWidth,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${_strokeWidth.round()} px',
                      onChanged: (value) =>
                          setState(() => _strokeWidth = value),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Hoàn tác'),
                    onPressed: _strokes.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: context.tr('Làm lại'),
                    onPressed: _redoStack.isEmpty ? null : _redo,
                    icon: const Icon(Icons.redo_rounded),
                  ),
                  IconButton(
                    tooltip: context.tr('Xóa trang vẽ'),
                    onPressed: _strokes.isEmpty ? null : _clearCanvas,
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: widget.readOnly
                      ? null
                      : (details) {
                          if (_isEraser) {
                            _eraseAt(details.localPosition);
                          } else {
                            _redoStack.clear();
                            setState(() {
                              _currentStroke = _StrokePath(
                                points: [details.localPosition],
                                color: _selectedColor,
                                strokeWidth: _strokeWidth,
                              );
                              _strokes.add(_currentStroke!);
                            });
                          }
                        },
                  onPanUpdate: widget.readOnly
                      ? null
                      : (details) {
                          if (_isEraser) {
                            _eraseAt(details.localPosition);
                          } else {
                            setState(
                              () => _currentStroke?.points.add(
                                details.localPosition,
                              ),
                            );
                          }
                        },
                  child: CustomPaint(
                    painter: _NotePainter(strokes: _strokes),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          if (constraints.maxHeight > 640 && !widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AppButton(
                text: _editingNoteId == null
                    ? 'Lưu ghi chú'
                    : 'Cập nhật ghi chú',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _saveNote,
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.brass : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}

class _StrokePath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  _StrokePath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class _NotePainter extends CustomPainter {
  final List<_StrokePath> strokes;

  _NotePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.line.withValues(alpha: .8)
      ..strokeWidth = 1;
    for (double y = 38; y < size.height; y += 34) {
      canvas.drawLine(Offset(22, y), Offset(size.width - 18, y), linePaint);
    }
    final marginPaint = Paint()
      ..color = AppColors.error.withValues(alpha: .16)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(48, 0), Offset(48, size.height), marginPaint);
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          math.max(stroke.strokeWidth / 2, 1),
          paint,
        );
      }
      for (var index = 0; index < stroke.points.length - 1; index++) {
        canvas.drawLine(stroke.points[index], stroke.points[index + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NotePainter oldDelegate) => true;
}
