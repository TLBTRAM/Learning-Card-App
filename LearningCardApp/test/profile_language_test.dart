import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learningcardapp/providers/auth_provider.dart';
import 'package:learningcardapp/providers/dashboard_provider.dart';
import 'package:learningcardapp/providers/language_provider.dart';
import 'package:learningcardapp/providers/theme_provider.dart';
import 'package:learningcardapp/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile only shows theme and a working language picker', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhắc lịch ôn tập'), findsNothing);
    expect(find.text('Mục tiêu hằng ngày'), findsNothing);
    expect(find.text('Trợ giúp & phản hồi'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Ngôn ngữ'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ngôn ngữ'));
    await tester.pumpAndSettle();

    expect(find.text('Tiếng Việt'), findsWidgets);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Study profile'), findsOneWidget);
  });
}
