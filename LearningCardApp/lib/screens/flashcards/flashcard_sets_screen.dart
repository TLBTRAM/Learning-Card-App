import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/flashcard_set_provider.dart';
import 'flashcard_detail_screen.dart';

class FlashcardSetsScreen extends StatefulWidget {
  const FlashcardSetsScreen({super.key});

  @override
  State<FlashcardSetsScreen> createState() => _FlashcardSetsScreenState();
}

class _FlashcardSetsScreenState extends State<FlashcardSetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardSetProvider>().loadSets();
    });
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tao flashcard set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huy')),
          ElevatedButton(
            onPressed: () async {
              await context.read<FlashcardSetProvider>().createSet(title: titleController.text.trim(), description: descController.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Luu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardSetProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcard Sets')),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateDialog, child: const Icon(Icons.add)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.sets.isEmpty
              ? const Center(child: Text('Chua co bo the nao. Nhan + de tao bo the dau tien.'))
              : RefreshIndicator(
                  onRefresh: provider.loadSets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.sets.length,
                    itemBuilder: (_, index) {
                      final set = provider.sets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          title: Text(set.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${set.description}\n${set.cardCount} cards'),
                          isThreeLine: true,
                          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => context.read<FlashcardSetProvider>().deleteSet(set.id)),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardDetailScreen(flashcardSet: set))),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}