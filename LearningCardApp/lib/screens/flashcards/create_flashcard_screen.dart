import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/flashcard_provider.dart';

class CreateFlashcardScreen extends StatefulWidget {
  final int setId;

  const CreateFlashcardScreen({super.key, required this.setId});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _exampleController = TextEditingController();

  Future<void> _save() async {
    await context.read<FlashcardProvider>().createCard(setId: widget.setId, front: _frontController.text.trim(), back: _backController.text.trim(), example: _exampleController.text.trim());
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Flashcard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _frontController, decoration: const InputDecoration(labelText: 'Front')),
          const SizedBox(height: 16),
          TextField(controller: _backController, decoration: const InputDecoration(labelText: 'Back')),
          const SizedBox(height: 16),
          TextField(controller: _exampleController, decoration: const InputDecoration(labelText: 'Example')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save Card')),
        ],
      ),
    );
  }
}