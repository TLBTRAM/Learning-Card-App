import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../models/share_recipient_model.dart';
import '../services/note_service.dart';

class NoteProvider extends ChangeNotifier {
  final NoteService _service = NoteService();

  List<NoteModel> notes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadNotes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      notes = await _service.getNotes();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<NoteModel?> saveNote({
    int? id,
    required String title,
    required String contentText,
    required List<dynamic> drawingData,
  }) async {
    try {
      final note = id == null
          ? await _service.createNote(
              title: title,
              contentText: contentText,
              drawingData: drawingData,
            )
          : await _service.updateNote(
              id: id,
              title: title,
              contentText: contentText,
              drawingData: drawingData,
            );
      await loadNotes();
      return note;
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteNote(int id) async {
    await _service.deleteNote(id);
    await loadNotes();
  }

  Future<List<ShareRecipient>> getShares(int noteId) =>
      _service.getShares(noteId);

  Future<void> shareWithEmail(int noteId, String email) async {
    await _service.shareWithEmail(noteId, email);
    await loadNotes();
  }

  Future<void> revokeShare(int noteId, int userId) async {
    await _service.revokeShare(noteId, userId);
    await loadNotes();
  }

  Future<void> updateVisibility(int noteId, String visibility) async {
    await _service.updateVisibility(noteId, visibility);
    await loadNotes();
  }

  void clear() {
    notes = [];
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}
