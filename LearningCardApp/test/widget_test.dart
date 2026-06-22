import 'package:flutter_test/flutter_test.dart';

import 'package:learningcardapp/main.dart';

void main() {
  testWidgets('app boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartFlashcardNotesApp());
    await tester.pump();
    expect(find.text('LearningCardApp'), findsOneWidget);
  });
}
