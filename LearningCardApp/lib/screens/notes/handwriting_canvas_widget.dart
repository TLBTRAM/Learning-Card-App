import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';

class HandwritingCanvasWidget extends StatefulWidget {
  final NoteModel? noteToLoad;
  final VoidCallback onClearSelection;
  const HandwritingCanvasWidget({super.key, this.noteToLoad, required this.onClearSelection});

  @override
  State<HandwritingCanvasWidget> createState() => _HandwritingCanvasWidgetState();
}

class _HandwritingCanvasWidgetState extends State<HandwritingCanvasWidget> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<_StrokePath> _strokes = [];
  _StrokePath? _currentStroke;
  Color _selectedColor = Colors.black;
  final double _strokeWidth = 4;
  int? _editingNoteId;

  @override
  void didUpdateWidget(covariant HandwritingCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.noteToLoad != null) _loadNote(widget.noteToLoad!);
  }

  void _loadNote(NoteModel note) {
    _titleController.text = note.title;
    _contentController.text = note.contentText;
    _editingNoteId = note.id;
    _strokes.clear();
    _strokes.addAll(note.drawingData.map((item) {
      final map = Map<String, dynamic>.from(item);
      final points = (map['points'] as List<dynamic>)
          .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList();
      return _StrokePath(
        points: points,
        color: Color(int.parse(map['color'].toString().replaceAll('#', 'FF'), radix: 16)),
        strokeWidth: (map['strokeWidth'] as num).toDouble(),
      );
    }));
    setState(() {});
  }

  void _undo() => setState(() { if (_strokes.isNotEmpty) _strokes.removeLast(); });
  void _clear() => setState(() => _strokes.clear());

  Future<void> _saveNote() async {
    final provider = context.read<NoteProvider>();
    final note = await provider.saveNote(
      id: _editingNoteId,
      title: _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim(),
      contentText: _contentController.text.trim(),
      drawingData: _strokes.map((s) => {
        'points': s.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'color': '#${s.color.value.toRadixString(16).substring(2).toUpperCase()}',
        'strokeWidth': s.strokeWidth,
      }).toList(),
    );
    if (mounted && note != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu!')));
      widget.onClearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Column(children: [
          _buildModernTextField(_titleController, "Tiêu đề ghi chú", Icons.title),
          const SizedBox(height: 12),
          _buildModernTextField(_contentController, "Nội dung chi tiết", Icons.edit_note),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Row(children: [
          ...[Colors.black, Colors.deepPurple, Colors.orange, Colors.blue].map((c) => GestureDetector(
            onTap: () => setState(() => _selectedColor = c),
            child: Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                    border: Border.all(color: _selectedColor == c ? const Color(0xFF7C6CFF) : Colors.transparent, width: 3))),
          )),
          const Spacer(),
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo, color: Colors.grey)),
          IconButton(onPressed: _clear, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
        ])),
        Expanded(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GestureDetector(
              onPanStart: (d) => setState(() => _strokes.add(_currentStroke = _StrokePath(points: [d.localPosition], color: _selectedColor, strokeWidth: _strokeWidth))),
              onPanUpdate: (d) => setState(() => _currentStroke?.points.add(d.localPosition)),
              child: CustomPaint(painter: _NotePainter(strokes: _strokes), child: const SizedBox.expand()),
            ),
          ),
        )),
        Container(
          width: double.infinity, margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF7C6CFF), Color(0xFF9D8EFF)])),
          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _saveNote, child: const Text('Lưu ghi chú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        )
      ],
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint, filled: true, fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: const Color(0xFF7C6CFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }
}

class _StrokePath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  _StrokePath({required this.points, required this.color, required this.strokeWidth});
}

class _NotePainter extends CustomPainter {
  final List<_StrokePath> strokes;
  _NotePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()..color = const Color(0xFFEAEAEA)..strokeWidth = 1;
    for (double y = 32; y < size.height; y += 32) canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    for (final stroke in strokes) {
      final paint = Paint()..color = stroke.color..strokeWidth = stroke.strokeWidth..strokeCap = StrokeCap.round;
      for (int i = 0; i < stroke.points.length - 1; i++) canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}