import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/hash/handover_hasher.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/handover/handover_screen.dart';
import 'package:kabadiwala_connect/features/recycler_mode/verify_screen.dart';

import 'helpers.dart';

final _h = HandoverHasher.create(
  id: 'h-1',
  lotId: 'lot-1',
  collectorUid: 'uid-1',
  recyclerId: 'rec_a',
  materialCode: 'PCB',
  weightGrams: 2000,
  agreedPaise: 42000,
  createdAt: DateTime.utc(2026, 10, 24, 12),
  lat: 29.8543,
  lng: 77.888,
  photoHashes: const ['aa'],
);

List _catalog() => [
  materialsProvider.overrideWith(
    (ref) => Stream.value(const [
      ScrapMaterial(
        code: 'PCB',
        nameKey: 'mat_PCB',
        iconAsset: 'memory',
        hazard: Hazard.low,
      ),
    ]),
  ),
  pricesProvider.overrideWith(
    (ref) => Stream.value(const [
      Price(materialCode: 'PCB', lowPaisePerKg: 18000, highPaisePerKg: 22000),
    ]),
  ),
];

Future<FakeAudio> _verify(
  WidgetTester tester,
  String payload, {
  String recyclerId = 'rec_a',
}) async {
  phoneScreen(tester);
  final audio = FakeAudio();
  await tester.pumpWidget(
    testApp(
      VerifyScreen(payload: payload),
      prefs: await freshPrefs({
        'language': 'en',
        'role': 'recycler',
        'recycler_id': recyclerId,
      }),
      audio: audio,
      overrides: _catalog(),
    ),
  );
  await tester.pump();
  return audio;
}

void main() {
  test('reference is spoken one character at a time', () {
    expect(HandoverScreen.spokenRef('A3F9-1C2B'), 'A 3 F 9, 1 C 2 B');
  });

  testWidgets('collector receipt: QR, short reference, pending status', (
    tester,
  ) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(
        HandoverScreen(handover: _h, recyclerName: 'Recycler A'),
        prefs: await freshPrefs({'language': 'en'}),
        audio: audio,
      ),
    );
    await tester.pump();
    expect(find.text(HandoverHasher.shortRef(_h.hash)), findsOneWidget);
    expect(find.text('Waiting for confirmation'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(audio.spoken.first, 'handover_instruction');
  });

  testWidgets('genuine QR: green, then weight and cash enable Confirm', (
    tester,
  ) async {
    final audio = await _verify(tester, HandoverHasher.qrPayload(_h));
    expect(find.text('Record is genuine'), findsOneWidget);
    expect(audio.spoken.first, 'verify_ok');

    final confirm = find.widgetWithText(FilledButton, 'Confirm');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.tap(find.text('Cash'));
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(find.text('₹420'), findsOneWidget);

    // Measured 0.5 kg less than declared 2 kg = 25% off: warning shown.
    await tester.tap(find.text('−½'));
    await tester.pump();
    expect(find.text('Weight differs by more than 10 percent'), findsOneWidget);
    expect(find.text('₹315'), findsOneWidget);
  });

  testWidgets('tampered QR (weight changed): red warning', (tester) async {
    final m = jsonDecode(HandoverHasher.qrPayload(_h)) as Map;
    m['w'] = 9000;
    final audio = await _verify(tester, jsonEncode(m));
    expect(find.text('Warning! The record was changed'), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsWidgets);
    expect(audio.spoken.first, 'verify_bad');
  });

  testWidgets('someone else\'s deal cannot be confirmed', (tester) async {
    await _verify(tester, HandoverHasher.qrPayload(_h), recyclerId: 'rec_b');
    expect(find.text('This deal is for a different recycler'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
  });

  testWidgets('a random QR code is rejected', (tester) async {
    await _verify(tester, 'https://example.com');
    expect(find.text('This is not a valid QR code'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
  });
}
