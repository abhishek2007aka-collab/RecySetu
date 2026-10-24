import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/app.dart';
import 'package:kabadiwala_connect/core/app_providers.dart';
import 'package:kabadiwala_connect/core/i18n/app_strings.dart';
import 'package:kabadiwala_connect/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

AppStrings _strings(String code, String ready) => AppStrings(code, {
  'app_name': 'Kabadiwala Connect',
  'firebase_ready': ready,
  'firebase_not_ready': 'not ready ($code)',
  'lang_name': code,
});

Widget _app({required bool firebaseReady}) => ProviderScope(
  overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    allStringsProvider.overrideWithValue({
      for (final c in ['hi', 'en', 'mr', 'gbm'])
        c: _strings(c, c == 'en' ? 'Server connected' : 'सर्वर जुड़ा ($c)'),
    }),
    firebaseReadyProvider.overrideWithValue(firebaseReady),
  ],
  child: const KabadiwalaApp(),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('shows amber clock when Firebase is not ready', (tester) async {
    await tester.pumpWidget(_app(firebaseReady: false));
    expect(find.text('not ready (hi)'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('shows green tick when Firebase is ready', (tester) async {
    await tester.pumpWidget(_app(firebaseReady: true));
    expect(find.text('सर्वर जुड़ा (hi)'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('switching language changes text instantly and is saved', (
    tester,
  ) async {
    await tester.pumpWidget(_app(firebaseReady: true));
    await tester.tap(find.text('en'));
    await tester.pump();
    expect(find.text('Server connected'), findsOneWidget);
    expect(prefs.getString('language'), 'en');
  });

  test('buttons are at least 56 dp', () {
    final size = AppTheme.light().filledButtonTheme.style!.minimumSize!.resolve(
      {},
    )!;
    expect(size.height, greaterThanOrEqualTo(56));
  });
}
