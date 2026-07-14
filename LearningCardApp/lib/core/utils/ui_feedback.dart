import '../localization/localized_material.dart';

abstract final class UiFeedback {
  static String friendlyError(Object? error, {String? fallback}) {
    final value = error?.toString().toLowerCase() ?? '';
    if (value.contains('socket') ||
        value.contains('connection') ||
        value.contains('timeout')) {
      return 'Không thể kết nối máy chủ. Hãy kiểm tra mạng và thử lại.';
    }
    if (value.contains('401') ||
        value.contains('unauthorized') ||
        value.contains('mật khẩu')) {
      return 'Email hoặc mật khẩu chưa đúng. Bạn kiểm tra lại nhé.';
    }
    if (value.contains('409') || value.contains('tồn tại')) {
      return 'Email này đã được sử dụng. Hãy đăng nhập hoặc chọn email khác.';
    }
    return fallback ?? 'Có điều gì đó chưa ổn. Vui lòng thử lại sau.';
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static void showError(
    BuildContext context,
    Object? error, {
    String? fallback,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(friendlyError(error, fallback: fallback))),
            ],
          ),
        ),
      );
  }
}
