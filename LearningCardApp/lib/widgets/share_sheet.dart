import '../core/localization/localized_material.dart';

import '../core/utils/ui_feedback.dart';
import '../models/share_recipient_model.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'premium_surface.dart';

class ShareSheet extends StatefulWidget {
  final String resourceName;
  final String initialVisibility;
  final Future<List<ShareRecipient>> Function() loadRecipients;
  final Future<void> Function(String email) shareWithEmail;
  final Future<void> Function(int userId) revokeShare;
  final Future<void> Function(String visibility) updateVisibility;

  const ShareSheet({
    super.key,
    required this.resourceName,
    required this.initialVisibility,
    required this.loadRecipients,
    required this.shareWithEmail,
    required this.revokeShare,
    required this.updateVisibility,
  });

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final _emailController = TextEditingController();
  List<ShareRecipient> _recipients = [];
  bool _isLoading = true;
  bool _isSharing = false;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.initialVisibility == 'public';
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final recipients = await widget.loadRecipients();
      if (mounted) setState(() => _recipients = recipients);
    } catch (error) {
      if (mounted) {
        UiFeedback.showError(
          context,
          error,
          fallback: 'Chưa tải được danh sách chia sẻ.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _share() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w-.]+@[\w-]+\.[\w-.]+$').hasMatch(email)) {
      UiFeedback.showError(
        context,
        null,
        fallback: 'Vui lòng nhập email hợp lệ.',
      );
      return;
    }
    setState(() => _isSharing = true);
    try {
      await widget.shareWithEmail(email);
      _emailController.clear();
      await _load();
      if (mounted) UiFeedback.showSuccess(context, 'Đã cấp quyền xem.');
    } catch (error) {
      if (mounted) {
        UiFeedback.showError(
          context,
          error,
          fallback: 'Không tìm thấy tài khoản hoặc chưa thể chia sẻ.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _changeVisibility(bool value) async {
    final previous = _isPublic;
    setState(() => _isPublic = value);
    try {
      await widget.updateVisibility(value ? 'public' : 'private');
      if (mounted) {
        UiFeedback.showSuccess(
          context,
          value
              ? 'Mọi người có thể tìm thấy tài nguyên này.'
              : 'Tài nguyên đã chuyển về riêng tư.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isPublic = previous);
        UiFeedback.showError(
          context,
          error,
          fallback: 'Chưa thể thay đổi quyền riêng tư.',
        );
      }
    }
  }

  Future<void> _revoke(ShareRecipient recipient) async {
    try {
      await widget.revokeShare(recipient.id);
      await _load();
      if (mounted) {
        UiFeedback.showSuccess(context, 'Đã thu hồi quyền truy cập.');
      }
    } catch (error) {
      if (mounted) UiFeedback.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chia sẻ ${widget.resourceName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Mặc định chỉ bạn nhìn thấy. Người được chia sẻ chỉ có quyền xem và học.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              PremiumSurface(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  secondary: Icon(
                    _isPublic
                        ? Icons.public_rounded
                        : Icons.lock_outline_rounded,
                    color: _isPublic
                        ? AppColors.success
                        : AppColors.lavenderDeep,
                  ),
                  title: Text(_isPublic ? 'Công khai' : 'Riêng tư'),
                  subtitle: Text(
                    _isPublic
                        ? 'Mọi tài khoản có thể tìm và xem'
                        : 'Chỉ bạn và người được mời có thể xem',
                  ),
                  value: _isPublic,
                  onChanged: _changeVisibility,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr('Email người nhận'),
                  hintText: 'banhoc@example.com',
                  prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                ),
                onSubmitted: (_) => _share(),
              ),
              const SizedBox(height: 10),
              AppButton(
                text: 'Chia sẻ quyền xem',
                icon: Icons.send_outlined,
                isLoading: _isSharing,
                onPressed: _share,
              ),
              const SizedBox(height: 22),
              Text(
                'Đang có quyền truy cập',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_recipients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'Chưa chia sẻ riêng với tài khoản nào.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ..._recipients.map(
                  (recipient) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        recipient.name.isEmpty
                            ? '?'
                            : recipient.name.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(recipient.name),
                    subtitle: Text(recipient.email),
                    trailing: IconButton(
                      tooltip: context.tr('Thu hồi quyền'),
                      onPressed: () => _revoke(recipient),
                      icon: const Icon(
                        Icons.person_remove_outlined,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
