import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';

class EditFlashcardScreen extends StatefulWidget {
  final int setId;
  final Flashcard card;

  const EditFlashcardScreen({super.key, required this.setId, required this.card});

  @override
  State<EditFlashcardScreen> createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen> {
  late TextEditingController _frontController;
  late TextEditingController _backController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card.front);
    _backController = TextEditingController(text: widget.card.back);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chỉnh sửa thẻ")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _frontController, decoration: const InputDecoration(labelText: "Mặt trước")),
            TextField(controller: _backController, decoration: const InputDecoration(labelText: "Mặt sau")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await context.read<FlashcardProvider>().updateCard(
                  setId: widget.setId,
                  cardId: widget.card.id,
                  front: _frontController.text,
                  back: _backController.text,
                );
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Lưu thay đổi"),
            )
          ],
        ),
      ),
    );
  }
}