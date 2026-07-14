import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium_surface.dart';

class EditFlashcardScreen extends StatefulWidget {
  final int setId;
  final Flashcard card;

  const EditFlashcardScreen({
    super.key,
    required this.setId,
    required this.card,
  });

  @override
  State<EditFlashcardScreen> createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _exampleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card.front);
    _backController = TextEditingController(text: widget.card.back);
    _exampleController = TextEditingController(text: widget.card.example);
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await context.read<FlashcardProvider>().updateCard(
        setId: widget.setId,
        cardId: widget.card.id,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        example: _exampleController.text.trim(),
      );
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Đã lưu thay đổi.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        UiFeedback.showError(
          context,
          error,
          fallback: 'Chưa thể cập nhật thẻ lúc này.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thẻ')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: AppButton(
            text: 'Lưu thay đổi',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            PremiumSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MẶT TRƯỚC',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _frontController,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? context.tr('Vui lòng nhập thuật ngữ')
                        : null,
                    decoration: InputDecoration(
                      labelText: context.tr('Thuật ngữ'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'MẶT SAU',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _backController,
                    minLines: 3,
                    maxLines: 6,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? context.tr('Vui lòng nhập định nghĩa')
                        : null,
                    decoration: InputDecoration(
                      labelText: context.tr('Định nghĩa'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _exampleController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: context.tr('Ví dụ minh họa'),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
