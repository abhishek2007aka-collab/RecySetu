import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/features/onboarding/splash_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('shows logo, name, tagline and the team; then moves on', (
    tester,
  ) async {
    phoneScreen(tester);
    var done = 0;
    await tester.pumpWidget(
      testApp(
        SplashScreen(onDone: () => done++),
        prefs: await freshPrefs({'language': 'en'}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kabadiwala Connect'), findsOneWidget);
    expect(find.text('Fair price for every scrap'), findsOneWidget);
    expect(find.text('Developed by'), findsOneWidget);
    expect(find.text('ByteStorms'), findsOneWidget);
    expect(find.text('Smart India Hackathon 2026 · SIH26229'), findsOneWidget);
    expect(done, 0);

    await tester.pump(const Duration(seconds: 2));
    expect(done, 1);
  });

  testWidgets('a tap skips it, and it never finishes twice', (tester) async {
    phoneScreen(tester);
    var done = 0;
    await tester.pumpWidget(
      testApp(
        SplashScreen(onDone: () => done++),
        prefs: await freshPrefs({'language': 'hi'}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('कबाड़ीवाला कनेक्ट'), findsOneWidget);
    await tester.tap(find.text('ByteStorms'));
    expect(done, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(done, 1);
  });
}
