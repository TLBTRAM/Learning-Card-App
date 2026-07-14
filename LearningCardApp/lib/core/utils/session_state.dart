import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/flashcard_set_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/search_provider.dart';

abstract final class SessionState {
  static void clearUserData(BuildContext context) {
    context.read<FlashcardSetProvider>().clear();
    context.read<FlashcardProvider>().clear();
    context.read<NoteProvider>().clear();
    context.read<ChatProvider>().clear();
    context.read<DashboardProvider>().clear();
    context.read<ReviewProvider>().clear();
    context.read<SearchProvider>().clear();
  }
}
