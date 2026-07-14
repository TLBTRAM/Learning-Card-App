import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium_surface.dart';

class CreateFlashcardScreen extends StatefulWidget {
  final int setId;

  const CreateFlashcardScreen({super.key, required this.setId});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _exampleController = TextEditingController();
  bool _isSaving = false;

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
      await context.read<FlashcardProvider>().createCard(
        setId: widget.setId,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        example: _exampleController.text.trim(),
      );
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Đã thêm thẻ mới.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        UiFeedback.showError(
          context,
          error,
          fallback: 'Chưa thể lưu thẻ. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thẻ mới')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: AppButton(
            text: 'Lưu thẻ',
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
            Text(
              'Một thẻ tốt nên ngắn gọn ở mặt trước và rõ ràng ở mặt sau.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
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
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? context.tr('Vui lòng nhập thuật ngữ')
                        : null,
                    decoration: InputDecoration(
                      labelText: context.tr('Thuật ngữ hoặc câu hỏi'),
                      hintText: context.tr('Ví dụ: Photosynthesis'),
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
                      labelText: context.tr('Định nghĩa hoặc câu trả lời'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _exampleController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: context.tr('Ví dụ minh họa (tùy chọn)'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => UiFeedback.showSuccess(
                      context,
                      'Vị trí ảnh đã sẵn sàng để kết nối kho ảnh.',
                    ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Thêm hình ảnh'),
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
