import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/vision/scrap_classifier.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/sell_lot/category_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/sell_draft.dart';

import 'helpers.dart';

const _codes = {'PCB', 'CABLE_CU', 'CRT'};

void main() {
  test('Teachable Machine labels.txt is read without the numbers', () {
    expect(parseLabels('0 PCB\n1 CABLE_CU\n2 OTHER\n'), [
      'PCB',
      'CABLE_CU',
      'OTHER',
    ]);
    expect(parseLabels('PCB\r\nCRT'), ['PCB', 'CRT']);
  });

  test('centre crop keeps the middle square and drops alpha', () {
    // 4×2 RGBA image: pixel value = x * 10 + y.
    final rgba = Uint8List(4 * 2 * 4);
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 4; x++) {
        final i = (y * 4 + x) * 4;
        rgba.setAll(i, [x * 10 + y, 0, 0, 255]);
      }
    }
    final rgb = centerCropRgb(rgba, 4, 2, 2);
    expect(rgb.length, 2 * 2 * 3);
    expect([rgb[0], rgb[3], rgb[6], rgb[9]], [10, 20, 11, 21]);
  });

  group('suggestion (70% rule)', () {
    test('sure enough -> suggested', () {
      final s = pickSuggestion([
        {'PCB': 0.9, 'CRT': 0.1},
      ], _codes)!;
      expect(s.materialCode, 'PCB');
      expect(s.confidence, closeTo(0.9, 1e-9));
    });

    test('not sure enough -> no suggestion', () {
      expect(
        pickSuggestion([
          {'PCB': 0.69, 'CRT': 0.31},
        ], _codes),
        isNull,
      );
    });

    test('OTHER or an unknown label is never suggested', () {
      expect(
        pickSuggestion([
          {'OTHER': 0.95, 'PCB': 0.05},
        ], _codes),
        isNull,
      );
      expect(
        pickSuggestion([
          {'LAPTOP': 0.95},
        ], _codes),
        isNull,
      );
    });

    test('photos are averaged: one blurry photo does not win alone', () {
      expect(
        pickSuggestion([
          {'PCB': 0.95, 'CRT': 0.05},
          {'PCB': 0.30, 'CRT': 0.70},
        ], _codes),
        isNull, // PCB averages 0.625
      );
      expect(
        pickSuggestion([
          {'PCB': 0.95, 'CRT': 0.05},
          {'PCB': 0.80, 'CRT': 0.20},
        ], _codes)!.materialCode,
        'PCB',
      );
    });

    test('no photos -> no suggestion', () {
      expect(pickSuggestion(const [], _codes), isNull);
    });
  });

  testWidgets('suggested tile comes first, is badged and spoken', (
    tester,
  ) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(
        const CategoryScreen(),
        prefs: await freshPrefs({'language': 'en'}),
        audio: audio,
        overrides: [
          materialsProvider.overrideWith(
            (ref) => Stream.value(const [
              ScrapMaterial(
                code: 'PCB',
                nameKey: 'mat_PCB',
                iconAsset: 'memory',
                hazard: Hazard.low,
              ),
              ScrapMaterial(
                code: 'CRT',
                nameKey: 'mat_CRT',
                iconAsset: 'tv',
                hazard: Hazard.high,
              ),
            ]),
          ),
          draftSuggestionProvider.overrideWithValue(
            const Suggestion('CRT', 0.88),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Suggested'), findsOneWidget);
    final crt = tester.getTopLeft(find.text('Old TV'));
    final pcb = tester.getTopLeft(find.text('Circuit board'));
    expect(crt.dx < pcb.dx || crt.dy < pcb.dy, isTrue);
    expect(audio.spoken, contains('ai_suggestion'));
  });

  testWidgets('no model: screen works exactly as before', (tester) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(
        const CategoryScreen(),
        prefs: await freshPrefs({'language': 'en'}),
        audio: audio,
        overrides: [draftSuggestionProvider.overrideWithValue(null)],
      ),
    );
    await tester.pump();
    expect(find.text('Suggested'), findsNothing);
    expect(audio.spoken.first, 'category_instruction');
    expect(find.byType(GridView), findsOneWidget);
  });
}
