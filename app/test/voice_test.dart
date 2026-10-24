import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/audio/audio_service.dart';
import 'package:kabadiwala_connect/features/home/home_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('voice off: no automatic speech, speaker button still works', (
    tester,
  ) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    final prefs = await freshPrefs({'language': 'en', 'voice_on': false});
    await tester.pumpWidget(
      testApp(const HomeScreen(), prefs: prefs, audio: audio),
    );
    await tester.pump();
    expect(audio.spoken, isEmpty);

    // Tapping a tile does not talk either.
    await tester.tap(find.text('Safety'));
    await tester.pumpAndSettle();
    expect(audio.spoken, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The speaker button is an explicit request: it always speaks.
    await tester.tap(find.byIcon(Icons.volume_up));
    expect(audio.spoken, ['home_instruction']);
  });

  testWidgets('switching voice off stops speech; on again says so', (
    tester,
  ) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    final prefs = await freshPrefs({'language': 'en'});
    await tester.pumpWidget(
      testApp(const HomeScreen(), prefs: prefs, audio: audio),
    );
    await tester.pump();
    expect(audio.spoken, ['home_instruction']);

    await tester.tap(find.byIcon(Icons.record_voice_over));
    await tester.pump();
    expect(prefs.getBool('voice_on'), isFalse);
    expect(audio.stops, greaterThan(0));
    expect(find.text('Voice off'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.voice_over_off).first);
    await tester.pump();
    expect(prefs.getBool('voice_on'), isTrue);
    expect(audio.spoken.last, 'voice_on');
  });

  testWidgets('going back stops the voice', (tester) async {
    var stops = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [StopSpeechOnBack(() => stops++)],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(appBar: AppBar()),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(stops, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(stops, 1);
  });

  testWidgets('sync icon shows how many records wait to be sent', (
    tester,
  ) async {
    phoneScreen(tester);
    await tester.pumpWidget(
      testApp(
        const HomeScreen(),
        prefs: await freshPrefs({'language': 'en'}),
        unsentData: true,
      ),
    );
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });
}
