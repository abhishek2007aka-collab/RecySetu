import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/debug/demo_tools_screen.dart';
import 'package:kabadiwala_connect/features/safety/safety_cards.dart';
import 'package:kabadiwala_connect/features/safety/safety_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/category_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/weight_screen.dart';

import 'helpers.dart';

void main() {
  test(
    'every high-hazard material links to a card that has text in all languages',
    () {
      final materials = (jsonDecode(
        File('assets/seed/materials.json').readAsStringSync(),
      ) as List).map((m) => ScrapMaterial.fromMap(m as Map<String, dynamic>));
      final strings = realStrings();
      for (final m in materials.where((m) => m.hazard == Hazard.high)) {
        final cards = m.safetyCardIds
            .map(safetyCardById)
            .whereType<SafetyCard>();
        expect(cards, isNotEmpty, reason: m.code);
        for (final c in cards) {
          for (final s in strings.values) {
            expect(
              s.has(c.titleKey) && s.has(c.textKey),
              isTrue,
              reason: '${s.languageCode} ${c.id}',
            );
          }
        }
      }
    },
  );

  testWidgets('safety screen: 5 cards, tap to hear', (tester) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(
        const SafetyScreen(),
        prefs: await freshPrefs({'language': 'en'}),
        audio: audio,
      ),
    );
    await tester.pump();
    expect(audio.spoken.first, 'safety_instruction');
    await tester.tap(find.text('Never burn cables'));
    expect(audio.spoken.last, 'safety_no_burning_text');
  });

  testWidgets(
    'first time a dangerous item is chosen, its safety card plays first',
    (tester) async {
      phoneScreen(tester);
      final audio = FakeAudio();
      final prefs = await freshPrefs({'language': 'en'});
      Widget app() => testApp(
        const CategoryScreen(),
        prefs: prefs,
        audio: audio,
        overrides: [
          materialsProvider.overrideWith(
            (ref) => Stream.value(const [
              ScrapMaterial(
                code: 'CRT',
                nameKey: 'mat_CRT',
                iconAsset: 'tv',
                hazard: Hazard.high,
                safetyCardIds: ['no_break_crt'],
              ),
            ]),
          ),
        ],
      );
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.tap(find.text('Old TV'));
      await tester.pumpAndSettle();
      expect(find.byType(SafetyFirstScreen), findsOneWidget);
      expect(audio.spoken.last, 'safety_no_break_crt_text');

      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      expect(find.byType(WeightScreen), findsOneWidget);
      expect(prefs.getBool('safety_seen_CRT'), isTrue);

      // Second time: straight to the weight screen, with the short warning.
      await tester.pumpWidget(Container());
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.tap(find.text('Old TV'));
      await tester.pumpAndSettle();
      expect(find.byType(SafetyFirstScreen), findsNothing);
      expect(find.byType(WeightScreen), findsOneWidget);
      expect(audio.spoken, contains('hazard_warning'));
    },
  );

  testWidgets('demo tools: reset safety cards so they play again', (
    tester,
  ) async {
    phoneScreen(tester);
    final prefs = await freshPrefs({
      'language': 'en',
      'safety_seen_CRT': true,
      'safety_seen_BATTERY_LI': true,
    });
    await tester.pumpWidget(testApp(const DemoToolsScreen(), prefs: prefs));
    await tester.pump();
    await tester.tap(find.text('Show safety cards again'));
    await tester.pump();
    expect(prefs.getBool('safety_seen_CRT'), isNull);
    expect(prefs.getBool('safety_seen_BATTERY_LI'), isNull);
  });
}
