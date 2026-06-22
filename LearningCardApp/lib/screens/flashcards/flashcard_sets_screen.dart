import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/flashcard_provider.dart';

class FlashcardSetsScreen extends StatefulWidget {
  const FlashcardSetsScreen({super.key});

  @override
  State<FlashcardSetsScreen> createState() => _FlashcardSetsScreenState();
}

class _FlashcardSetsScreenState extends State<FlashcardSetsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FlashcardProvider>().loadSets();
    });
  }

  void showCreateDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Create Flashcard Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<FlashcardProvider>().addSet(
                  titleController.text,
                  descriptionController.text,
                );

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Sets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Set'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: provider.sets.length,
        itemBuilder: (context, index) {
          final set = provider.sets[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.style,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                title: Text(
                  set.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(set.description),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            ),
          );
        },
      ),
    );
  }
}