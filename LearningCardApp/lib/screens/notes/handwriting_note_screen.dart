import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import 'saved_notes_screen.dart';
import '../../models/note_model.dart';
import 'handwriting_canvas_widget.dart';

class HandwritingNoteScreen extends StatefulWidget {
  final NoteModel? noteToLoad;
  const HandwritingNoteScreen({super.key, this.noteToLoad});

  @override
  State<HandwritingNoteScreen> createState() => _HandwritingNoteScreenState();
}

class _HandwritingNoteScreenState extends State<HandwritingNoteScreen> {
  int _currentIndex = 0;
  NoteModel? _editingNote;

  @override
  void didUpdateWidget(covariant HandwritingNoteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.noteToLoad != null) {
      setState(() {
        _editingNote = widget.noteToLoad;
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                HandwritingCanvasWidget(
                  noteToLoad: _editingNote,
                  onClearSelection: () => setState(() => _editingNote = null),
                ),
                SavedNotesScreen(onNoteTap: (note) {
                  setState(() {
                    _editingNote = note;
                    _currentIndex = 0;
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _buildTabItem("Handwriting", 0),
          _buildTabItem("Lịch sử", 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Text(title, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF7C6CFF) : Colors.grey)),
        ),
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
    final guidePaint = Paint()
      ..color = const Color(0xFFEAEAEA)
      ..strokeWidth = 1;
    for (double y = 32; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}