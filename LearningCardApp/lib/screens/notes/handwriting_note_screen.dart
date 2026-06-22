import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note_model.dart';
import '../../providers/note_provider.dart';

class HandwritingNoteScreen extends StatefulWidget {
  const HandwritingNoteScreen({super.key});

  @override
  State<HandwritingNoteScreen> createState() => _HandwritingNoteScreenState();
}

class _HandwritingNoteScreenState extends State<HandwritingNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<_StrokePath> _strokes = [];
  _StrokePath? _currentStroke;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4;
  int? _editingNoteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
    });
  }

  String _colorToHex(Color color) => '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  List<dynamic> _toJsonData() {
    return _strokes
        .map((stroke) => {
              'points': stroke.points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
              'color': _colorToHex(stroke.color),
              'strokeWidth': stroke.strokeWidth,
            })
        .toList();
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
          final points = (map['points'] as List<dynamic>)
              .map((point) => Offset((point['x'] as num).toDouble(), (point['y'] as num).toDouble()))
              .toList();
          return _StrokePath(points: points, color: _hexToColor(map['color'] ?? '#000000'), strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 4);
        }),
      );
    setState(() {});
  }

  Future<void> _saveNote() async {
    final provider = context.read<NoteProvider>();
    final note = await provider.saveNote(
      id: _editingNoteId,
      title: _titleController.text.trim().isEmpty ? 'Untitled Note' : _titleController.text.trim(),
      contentText: _contentController.text.trim(),
      drawingData: _toJsonData(),
    );
    if (!mounted) return;
    if (note != null) {
      _editingNoteId = note.id;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Da luu note')));
    }
  }

  void _clearCanvas() {
    _strokes.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Handwriting Notes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Ten note')),
          const SizedBox(height: 12),
          TextField(controller: _contentController, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chu text ngan')),
          const SizedBox(height: 16),
          Row(
            children: [
              ...[Colors.black, Colors.deepPurple, Colors.orange, Colors.blue].map(
                (color) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _selectedColor == color ? Colors.black : Colors.transparent, width: 2)),
                  ),
                ),
              ),
              Expanded(
                child: Slider(value: _strokeWidth, min: 2, max: 12, label: _strokeWidth.toStringAsFixed(0), onChanged: (value) => setState(() => _strokeWidth = value)),
              ),
              IconButton(onPressed: _clearCanvas, icon: const Icon(Icons.delete_sweep_outlined)),
            ],
          ),
          Container(
            height: 380,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: GestureDetector(
              onPanStart: (details) {
                _currentStroke = _StrokePath(points: [details.localPosition], color: _selectedColor, strokeWidth: _strokeWidth);
                _strokes.add(_currentStroke!);
                setState(() {});
              },
              onPanUpdate: (details) {
                _currentStroke?.points.add(details.localPosition);
                setState(() {});
              },
              onPanEnd: (_) => _currentStroke = null,
              child: CustomPaint(painter: _NotePainter(strokes: _strokes), child: const SizedBox.expand()),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _saveNote, child: const Text('Luu note')),
          const SizedBox(height: 20),
          const Text('Saved Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.notes.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('Chua co note nao.'))
          else
            ...provider.notes.map(
              (note) => Card(
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.contentText.isEmpty ? 'Co du lieu drawing canvas' : note.contentText),
                  onTap: () => _loadNote(note),
                  trailing: IconButton(onPressed: () => context.read<NoteProvider>().deleteNote(note.id), icon: const Icon(Icons.delete_outline)),
                ),
              ),
            ),
        ],
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
