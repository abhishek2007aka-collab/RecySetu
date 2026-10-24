import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/home/home_screen.dart';
import 'package:kabadiwala_connect/features/ledger/ledger_screen.dart';
import 'package:kabadiwala_connect/features/onboarding/language_pick_screen.dart';
import 'package:kabadiwala_connect/features/prices/rates_board_screen.dart';
import 'package:kabadiwala_connect/features/safety/safety_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/category_screen.dart';
import 'package:kabadiwala_connect/features/sell_lot/weight_screen.dart';

import 'helpers.dart';

/// Older users often set the phone's font size to the maximum. Every main
/// screen must still lay out without overflow at 2x text on a 360 dp phone,
/// in a long-word language too.
void main() {
  final screens = <String, Widget>{
    'home': const HomeScreen(),
    'language': const LanguagePickScreen(),
    'category': const CategoryScreen(),
    'weight': const WeightScreen(),
    'rates': const RatesBoardScreen(),
    'ledger': const LedgerScreen(),
    'safety': const SafetyScreen(),
  };

  for (final lang in ['hi', 'ta']) {
    screens.forEach((name, screen) {
      testWidgets('$name fits at 2x font ($lang)', (tester) async {
        phoneScreen(tester);
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          testApp(
            screen,
            prefs: await freshPrefs({'language': lang}),
            overrides: [
              pricesProvider.overrideWith(
                (ref) => Stream.value(const [
                  Price(
                    materialCode: 'PCB',
                    lowPaisePerKg: 8000,
                    highPaisePerKg: 20000,
                  ),
                ]),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    });
  }
}
