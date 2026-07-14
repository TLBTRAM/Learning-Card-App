import 'package:flutter_test/flutter_test.dart';
import 'package:learningcardapp/core/localization/app_translator.dart';
import 'package:learningcardapp/providers/language_provider.dart';

void main() {
  test('translates main and create-set copy to English and Japanese', () {
    expect(
      AppTranslator.translate('Hoạt động hôm nay', AppLanguage.en),
      'Today’s activity',
    );
    expect(
      AppTranslator.translate('Tạo bộ flashcard', AppLanguage.en),
      'Create flashcard set',
    );
    expect(AppTranslator.translate('Tên bộ flashcard', AppLanguage.ja), 'セット名');
    expect(AppTranslator.translate('Định nghĩa', AppLanguage.ja), '定義');
  });

  test('translates dynamic ownership and progress copy', () {
    expect(
      AppTranslator.translate('6 thẻ · Tạo bởi Minh', AppLanguage.en),
      '6 cards · Created by Minh',
    );
    expect(AppTranslator.translate('7/18 thẻ', AppLanguage.ja), '7/18枚');
    expect(AppTranslator.translate('THẺ 2', AppLanguage.en), 'CARD 2');
    expect(
      AppTranslator.translate('5 bộ thẻ trong thư viện', AppLanguage.en),
      '5 sets in your library',
    );
    expect(
      AppTranslator.translate('3 của bạn · 2 được chia sẻ', AppLanguage.en),
      '3 owned · 2 shared',
    );
  });
}
