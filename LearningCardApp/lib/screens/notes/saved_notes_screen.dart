import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../models/note_model.dart';

class SavedNotesScreen extends StatelessWidget {
  final Function(NoteModel) onNoteTap;
  const SavedNotesScreen({super.key, required this.onNoteTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, child) {
        final notes = provider.notes;
        if (notes.isEmpty) {
          return const Center(child: Text("Chưa có ghi chú nào", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(note.contentText, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => provider.deleteNote(note.id),
                ),
                onTap: () => onNoteTap(note),
              ),
            );
          },
        );
      },
    );
  }
}