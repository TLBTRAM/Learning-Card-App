import 'dart:async';

import '../../core/localization/localized_material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_feedback.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/flashcard_set_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/section_header.dart';

class CreateFlashcardSetScreen extends StatefulWidget {
  const CreateFlashcardSetScreen({super.key});

  @override
  State<CreateFlashcardSetScreen> createState() =>
      _CreateFlashcardSetScreenState();
}

class _CreateFlashcardSetScreenState extends State<CreateFlashcardSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_DraftCardControllers> _cards = [_DraftCardControllers()];
  final _colors = const ['#17233C', '#7565A7', '#4D8064', '#C7A565'];
  String _selectedColor = '#17233C';
  String _subject = 'Ngoại ngữ';
  bool _isSaving = false;
  bool _draftSaved = true;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_scheduleDraftSave);
    _descriptionController.addListener(_scheduleDraftSave);
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    if (mounted) setState(() => _draftSaved = false);
    _draftTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _draftSaved = true);
    });
  }

  void _addCard() {
    setState(() => _cards.add(_DraftCardControllers()));
    _scheduleDraftSave();
  }

  void _removeCard(int index) {
    if (_cards.length == 1) return;
    final card = _cards.removeAt(index);
    card.dispose();
    setState(() {});
    _scheduleDraftSave();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final setProvider = context.read<FlashcardSetProvider>();
    final cardProvider = context.read<FlashcardProvider>();
    try {
      final created = await setProvider.createSet(
        title: _titleController.text.trim(),
        description:
            '${_descriptionController.text.trim()}${_descriptionController.text.trim().isEmpty ? '' : ' · '}$_subject',
        color: _selectedColor,
      );
      for (final card in _cards) {
        if (card.term.text.trim().isEmpty ||
            card.definition.text.trim().isEmpty) {
          continue;
        }
        await cardProvider.createCard(
          setId: created.id,
          front: card.term.text.trim(),
          back: card.definition.text.trim(),
          example: card.example.text.trim(),
        );
      }
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Đã tạo bộ flashcard mới.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      UiFeedback.showError(
        context,
        error,
        fallback: 'Chưa thể lưu bộ thẻ. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bộ flashcard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _draftSaved
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  _draftSaved ? 'Đã lưu nháp' : 'Đang lưu...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: AppButton(
            text: 'Lưu bộ flashcard',
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
              'Xây dựng một bộ thẻ có cấu trúc rõ ràng để việc ôn tập nhẹ nhàng hơn.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Thông tin bộ thẻ'),
            const SizedBox(height: 12),
            PremiumSurface(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? context.tr('Vui lòng nhập tên bộ thẻ')
                        : null,
                    decoration: InputDecoration(
                      labelText: context.tr('Tên bộ flashcard'),
                      hintText: context.tr('Ví dụ: Academic English B2'),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: context.tr('Mô tả'),
                      hintText: context.tr(
                        'Mục tiêu hoặc nội dung chính của bộ thẻ',
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _subject,
                    decoration: InputDecoration(
                      labelText: context.tr('Chủ đề'),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    items:
                        const [
                              'Ngoại ngữ',
                              'Khoa học',
                              'Kinh tế',
                              'Công nghệ',
                              'Khác',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _subject = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Màu nhận diện',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _colors.map((hex) {
                      final color = _colorFromHex(hex);
                      final selected = _selectedColor == hex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => setState(() => _selectedColor = hex),
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: 'Nội dung thẻ',
              subtitle: '${_cards.length} thẻ trong bản nháp',
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _cards.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _DraftCardEditor(
                  index: index,
                  controllers: _cards[index],
                  onChanged: _scheduleDraftSave,
                  onRemove: () => _removeCard(index),
                  canRemove: _cards.length > 1,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _addCard,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm thẻ khác'),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromHex(String hex) =>
      Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
}

class _DraftCardEditor extends StatelessWidget {
  final int index;
  final _DraftCardControllers controllers;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  const _DraftCardEditor({
    required this.index,
    required this.controllers,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lavenderSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'THẺ ${index + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.lavenderDeep,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.tr('Xóa thẻ'),
                onPressed: canRemove ? onRemove : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controllers.term,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.tr('Thuật ngữ'),
              hintText: context.tr('Nội dung mặt trước'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controllers.definition,
            onChanged: (_) => onChanged(),
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.tr('Định nghĩa'),
              hintText: context.tr('Nội dung mặt sau'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controllers.example,
            onChanged: (_) => onChanged(),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.tr('Ví dụ (tùy chọn)'),
              hintText: context.tr('Một câu giúp ghi nhớ theo ngữ cảnh'),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => UiFeedback.showSuccess(
                context,
                'Vị trí ảnh đã sẵn sàng để kết nối kho ảnh.',
              ),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 19),
              label: const Text('Thêm hình ảnh'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCardControllers {
  final term = TextEditingController();
  final definition = TextEditingController();
  final example = TextEditingController();

  void dispose() {
    term.dispose();
    definition.dispose();
    example.dispose();
  }
}
