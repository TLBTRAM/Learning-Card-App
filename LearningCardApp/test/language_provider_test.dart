import 'package:flutter_test/flutter_test.dart';
import 'package:learningcardapp/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language selection changes copy and is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = LanguageProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.language, AppLanguage.vi);
    await provider.setLanguage(AppLanguage.ja);

    expect(provider.language, AppLanguage.ja);
    expect(provider.pick(vi: 'Việt', en: 'English', ja: '日本語'), '日本語');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language'), 'ja');
  });
}
