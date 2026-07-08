import 'package:flutter/material.dart';
import 'handwriting_note_screen.dart';
import 'saved_notes_screen.dart';
import '../../models/note_model.dart';

class NoteContainerScreen extends StatefulWidget {
  const NoteContainerScreen({super.key});

  @override
  State<NoteContainerScreen> createState() => _NoteContainerScreenState();
}

class _NoteContainerScreenState extends State<NoteContainerScreen> {
  int _currentIndex = 0;
  NoteModel? _noteToLoad;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildCustomTab("Handwriting", 0),
            _buildCustomTab("Ghi chú cũ", 1),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          HandwritingNoteScreen(noteToLoad: _noteToLoad),
          SavedNotesScreen(onNoteTap: (note) {
            setState(() {
              _noteToLoad = note;
              _currentIndex = 0;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildCustomTab(String title, int index) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF7C6CFF) : Colors.transparent, width: 2))
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}