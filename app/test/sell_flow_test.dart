import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kabadiwala_connect/core/format.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/sell_lot/category_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/estimate_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/sell_draft.dart';
import 'package:kabadiwala_connect/features/sell_lot/weight_screen.dart';

import 'helpers.dart';

void main() {
  group('Fmt', () {
    test('Indian grouping', () {
      expect(Fmt.indian(0), '0');
      expect(Fmt.indian(999), '999');
      expect(Fmt.indian(1340), '1,340');
      expect(Fmt.indian(150000), '1,50,000');
      expect(Fmt.indian(12345678), '1,23,45,678');
    });
    test('rupees from paise', () {
      expect(Fmt.rupees(30600), '₹306');
      expect(Fmt.rupees(15000050), '₹1,50,001');
    });
    test('kilos', () {
      expect(Fmt.kg(2500), '2.5');
      expect(Fmt.kg(3000), '3');
      expect(Fmt.kg(999), '1');
      expect(Fmt.kg(0), '0');
    });
  });

  test('weight stays between 0 and 1 tonne', () {
    final c = ProviderContainer();
    final n = c.read(sellDraftProvider.notifier);
    n.changeWeight(-5000);
    expect(c.read(sellDraftProvider).weightGrams, 0);
    n.setWeight(5 * 1000 * 1000);
    expect(c.read(sellDraftProvider).weightGrams, SellDraft.maxWeightGrams);
    c.dispose();
  });

  test('a new sale gets a new lot id; the same sale keeps it', () {
    final c = ProviderContainer();
    final first = c.read(sellDraftProvider).lotId;
    c.read(sellDraftProvider.notifier).changeWeight(500);
    expect(c.read(sellDraftProvider).lotId, first);
    c.read(sellDraftProvider.notifier).start();
    expect(c.read(sellDraftProvider).lotId, isNot(first));
    c.dispose();
  });

  testWidgets('category -> weight -> spoken price, offline, no typing', (
    tester,
  ) async {
    phoneScreen(tester);
    final prefs = await freshPrefs({'language': 'en'});
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(
        const CategoryScreen(),
        prefs: prefs,
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
            ]),
          ),
          pricesProvider.overrideWith(
            (ref) => Stream.value(const [
              Price(
                materialCode: 'PCB',
                lowPaisePerKg: 18000,
                highPaisePerKg: 22000,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pump();
    expect(audio.spoken.last, 'category_instruction');

    await tester.tap(find.text('Circuit board'));
    await tester.pumpAndSettle();
    expect(find.byType(WeightScreen), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // starts at 1 kg

    await tester.tap(find.text('+½'));
    await tester.pump();
    expect(find.text('1.5'), findsOneWidget);
    expect(audio.spoken.last, 'weight_spoken');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.byType(EstimateScreen), findsOneWidget);
    // 1.5 kg × ₹180–220 = ₹270–330 -> about ₹300
    expect(find.text('~₹300'), findsOneWidget);
    expect(find.text('₹270 – ₹330'), findsOneWidget);
    expect(audio.spoken, contains('price_estimate'));
  });
}
