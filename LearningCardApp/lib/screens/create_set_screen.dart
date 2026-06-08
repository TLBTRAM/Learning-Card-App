import 'package:flutter/material.dart';

class CreateSetScreen extends StatefulWidget {
  const CreateSetScreen({super.key});

  @override
  State<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends State<CreateSetScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  final termController = TextEditingController();
  final hiraganaController = TextEditingController();
  final definitionController = TextEditingController();

  List<Map<String, String>> cards = [];

  void addCard() {
    if (termController.text.isEmpty || definitionController.text.isEmpty) {
      return;
    }

    setState(() {
      cards.add({
        'term': termController.text,
        'hiragana': hiraganaController.text,
        'definition': definitionController.text,
      });

      termController.clear();
      hiraganaController.clear();
      definitionController.clear();
    });
  }

  void saveSet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Study set saved demo!'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    termController.dispose();
    hiraganaController.dispose();
    definitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F3EA),
      appBar: AppBar(
        title: const Text('Create Study Set'),
        backgroundColor: const Color(0xffF7F3EA),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Example: Japanese Lesson 7',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Example: Vocabulary and grammar',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Add Flashcard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: termController,
              decoration: InputDecoration(
                labelText: 'Term',
                hintText: 'Example: 試験',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: hiraganaController,
              decoration: InputDecoration(
                labelText: 'Hiragana',
                hintText: 'Example: しけん',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: definitionController,
              decoration: InputDecoration(
                labelText: 'Definition',
                hintText: 'Example: kỳ thi',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addCard,
                icon: const Icon(Icons.add),
                label: const Text('Add Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff5BA199),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Cards Added: ${cards.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...cards.map((card) {
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(card['term'] ?? ''),
                  subtitle: Text(
                    '${card['hiragana'] ?? ''} - ${card['definition'] ?? ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        cards.remove(card);
                      });
                    },
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Study Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}