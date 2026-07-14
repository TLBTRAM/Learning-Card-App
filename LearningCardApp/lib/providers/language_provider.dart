import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { vi, en, ja }

extension AppLanguageInfo on AppLanguage {
  String get nativeLabel => switch (this) {
    AppLanguage.vi => 'Tiếng Việt',
    AppLanguage.en => 'English',
    AppLanguage.ja => '日本語',
  };

  Locale get locale => Locale(name);
}

class LanguageProvider extends ChangeNotifier {
  static const _preferenceKey = 'app_language';

  AppLanguage _language = AppLanguage.vi;

  LanguageProvider() {
    _restoreLanguage();
  }

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  String pick({required String vi, required String en, required String ja}) {
    return switch (_language) {
      AppLanguage.vi => vi,
      AppLanguage.en => en,
      AppLanguage.ja => ja,
    };
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, value.name);
  }

  Future<void> _restoreLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_preferenceKey);
    final restored = AppLanguage.values.where((item) => item.name == saved);
    if (restored.isEmpty || restored.first == _language) return;
    _language = restored.first;
    notifyListeners();
  }
}
