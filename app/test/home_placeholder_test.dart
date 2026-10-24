import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/app.dart';
import 'package:kabadiwala_connect/core/i18n/app_strings.dart';
import 'package:kabadiwala_connect/core/theme/app_theme.dart';

Widget _app({required bool firebaseReady}) => ProviderScope(
  overrides: [
    appStringsProvider.overrideWithValue(
      AppStrings('en', const {
        'app_name': 'Kabadiwala Connect',
        'firebase_ready': 'Server connected',
        'firebase_not_ready': 'Server not set up yet',
      }),
    ),
    firebaseReadyProvider.overrideWithValue(firebaseReady),
  ],
  child: const KabadiwalaApp(),
);

void main() {
  testWidgets('shows amber clock when Firebase is not ready', (tester) async {
    await tester.pumpWidget(_app(firebaseReady: false));
    expect(find.text('Server not set up yet'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('shows green tick when Firebase is ready', (tester) async {
    await tester.pumpWidget(_app(firebaseReady: true));
    expect(find.text('Server connected'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  test('buttons are at least 56 dp', () {
    final size = AppTheme.light().filledButtonTheme.style!.minimumSize!.resolve(
      {},
    )!;
    expect(size.height, greaterThanOrEqualTo(56));
  });
}
