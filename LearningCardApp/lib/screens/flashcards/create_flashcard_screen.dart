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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Thêm thẻ mới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nội dung thẻ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 16),

            _buildTextField(controller: _frontController, label: "Mặt trước (Thuật ngữ)"),
            const SizedBox(height: 16),
            _buildTextField(controller: _backController, label: "Mặt sau (Giải nghĩa)"),
            const SizedBox(height: 16),
            _buildTextField(controller: _exampleController, label: "Ví dụ minh họa (Tùy chọn)", maxLines: 2),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6CFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: () async {
                  if (_frontController.text.isEmpty || _backController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đầy đủ mặt trước và mặt sau!')),
                    );
                    return;
                  }
                  await context.read<FlashcardProvider>().addCard(
                    widget.setId,
                    _frontController.text.trim(),
                    _backController.text.trim(),
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("Lưu thẻ nhớ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF7C6CFF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}