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

  Future<void> _showSetDialog(BuildContext context, {dynamic set}) async {
    final titleController = TextEditingController(text: set?.title ?? "");
    final descController = TextEditingController(text: set?.description ?? "");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF5F7FA)]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(set == null ? "Tạo bộ thẻ mới" : "Chỉnh sửa bộ thẻ",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildInputField(titleController, "Tiêu đề", Icons.title),
              const SizedBox(height: 15),
              _buildInputField(descController, "Mô tả", Icons.description_outlined),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6CFF), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  final provider = context.read<FlashcardSetProvider>();
                  if (set == null) {
                    await provider.createSet(title: titleController.text, description: descController.text);
                  } else {
                    await provider.updateSet(id: set.id, title: titleController.text, description: descController.text);
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text(set == null ? "Tạo ngay" : "Cập nhật", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) => TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF7C6CFF)), filled: true, fillColor: Colors.white.withOpacity(0.8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardSetProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcard Sets')),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF7C6CFF), onPressed: () => _showSetDialog(context), child: const Icon(Icons.add, color: Colors.white)),
      body: provider.isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.sets.length,
        itemBuilder: (context, index) {
          final set = provider.sets[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardDetailScreen(flashcardSet: set))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFF7C6CFF).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))]),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF7C6CFF).withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.style_outlined, color: Color(0xFF7C6CFF))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(set.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("${set.cardCount ?? 0} thẻ", style: TextStyle(color: Colors.grey.shade600))])),
                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent), onPressed: () => _showSetDialog(context, set: set)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => provider.deleteSet(set.id)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}