import '../core/localization/localized_material.dart';

import '../models/flashcard_model.dart';

class FlashcardItem extends StatelessWidget {
  final Flashcard card;
  final VoidCallback? onDelete;

  const FlashcardItem({super.key, required this.card, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          card.front,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(card.back),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
