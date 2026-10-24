import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/prices/rates_board_screen.dart';
import 'package:kabadiwala_connect/features/recyclers/recyclers_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/sell_draft.dart';

import 'helpers.dart';

const _materials = [
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
];

const _prices = [
  Price(
    materialCode: 'PCB',
    lowPaisePerKg: 18000,
    highPaisePerKg: 22000,
    weekAgoMidPaisePerKg: 19000,
  ),
  Price(
    materialCode: 'CRT',
    lowPaisePerKg: 1000,
    highPaisePerKg: 2000,
    weekAgoMidPaisePerKg: 2000,
  ),
];

Recycler _r(
  String id, {
  bool authorised = true,
  int pcb = 20000,
  double lat = 29.86,
}) => Recycler(
  id: id,
  name: 'Recycler $id',
  phone: '+910000000000',
  lat: lat,
  lng: 77.89,
  address: '',
  authorised: authorised,
  authorisationRef: '',
  offersPickup: false,
  ratesPaisePerKg: {'PCB': pcb},
);

List _catalog() => [
  materialsProvider.overrideWith((ref) => Stream.value(_materials)),
  pricesProvider.overrideWith((ref) => Stream.value(_prices)),
  recyclersProvider.overrideWith(
    (ref) => Stream.value([
      _r('A', pcb: 21000),
      _r('B', pcb: 20000, lat: 29.95),
      _r('Shady', authorised: false, pcb: 99900),
    ]),
  ),
  areasProvider.overrideWith(
    (ref) => Stream.value(const [
      Area(id: 'area_1', nameKey: 'area_1', lat: 29.86, lng: 77.89),
    ]),
  ),
];

/// The collector already chose "circuit board" before reaching S10.
Future<void> choosePcb(WidgetTester tester) async {
  ProviderScope.containerOf(tester.element(find.byType(RecyclersScreen)))
      .read(sellDraftProvider.notifier)
      .chooseMaterial('PCB');
  await tester.pump();
}

void main() {
  testWidgets('rates board: ranges, trend arrows, tap speaks', (tester) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(
        const RatesBoardScreen(),
        prefs: await freshPrefs({'language': 'en'}),
        audio: audio,
        overrides: _catalog(),
      ),
    );
    await tester.pump();
    expect(find.text('₹180–220'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget); // PCB 200 vs 190
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget); // CRT 15 vs 20
    await tester.tap(find.text('Circuit board'));
    expect(audio.spoken.last, 'rate_with_trend');
  });

  testWidgets('no location yet: explain, then pick an area, then the list', (
    tester,
  ) async {
    phoneScreen(tester);
    final prefs = await freshPrefs({'language': 'en'});
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(
        RecyclersScreen(onSelect: (_, _) {}),
        prefs: prefs,
        audio: audio,
        overrides: _catalog(),
      ),
    );
    await choosePcb(tester);
    expect(audio.spoken.last, 'location_why');

    await tester.tap(find.text('Area 1'));
    await tester.pumpAndSettle();
    expect(prefs.getDouble('my_lat'), 29.86);
    expect(find.text('Recycler A'), findsOneWidget);
  });

  testWidgets('recycler list: authorised only, best first, select works', (
    tester,
  ) async {
    phoneScreen(tester);
    String? chosen;
    await tester.pumpWidget(
      testApp(
        RecyclersScreen(onSelect: (_, c) => chosen = c.recycler.id),
        prefs: await freshPrefs({
          'language': 'en',
          'my_lat': 29.86,
          'my_lng': 77.89,
        }),
        overrides: _catalog(),
      ),
    );
    await choosePcb(tester);
    expect(find.text('Recycler Shady'), findsNothing);
    final a = tester.getTopLeft(find.text('Recycler A')).dy;
    final b = tester.getTopLeft(find.text('Recycler B')).dy;
    expect(a, lessThan(b));
    // Default draft is 1 kg: ₹210 at Recycler A.
    expect(find.text('~₹210'), findsOneWidget);
    await tester.tap(find.text('Choose').first);
    expect(chosen, 'A');
  });
}
