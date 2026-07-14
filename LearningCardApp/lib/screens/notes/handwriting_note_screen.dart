import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import 'handwriting_canvas_widget.dart';
import 'saved_notes_screen.dart';

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
  void initState() {
    super.initState();
    _editingNote = widget.noteToLoad;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
    });
  }

  @override
  void didUpdateWidget(covariant HandwritingNoteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.noteToLoad != null &&
        widget.noteToLoad != oldWidget.noteToLoad) {
      setState(() {
        _editingNote = widget.noteToLoad;
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sổ tay học tập'),
            Text(
              _editingNote == null
                  ? 'Ghi lại điều đáng nhớ'
                  : _editingNote!.isOwner
                  ? 'Đang chỉnh sửa ghi chú của bạn'
                  : 'Chỉ đọc · Tạo bởi ${_editingNote!.ownerName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: context.tr('Ghi chú mới'),
            onPressed: () => setState(() {
              _editingNote = null;
              _currentIndex = 0;
            }),
            icon: const Icon(Icons.note_add_outlined),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.draw_outlined),
                    label: Text('Trang viết'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.folder_open_outlined),
                    label: Text('Ghi chú đã lưu'),
                  ),
                ],
                selected: {_currentIndex},
                onSelectionChanged: (value) =>
                    setState(() => _currentIndex = value.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HandwritingCanvasWidget(
                    noteToLoad: _editingNote,
                    readOnly: _editingNote?.isOwner == false,
                    onClearSelection: () => setState(() => _editingNote = null),
                  ),
                  SavedNotesScreen(
                    onNoteTap: (note) => setState(() {
                      _editingNote = note;
                      _currentIndex = 0;
                    }),
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
