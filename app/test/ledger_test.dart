import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/ledger/ledger_screen.dart';
import 'package:kabadiwala_connect/core/ledger/ledger_summary.dart';
import 'package:kabadiwala_connect/data/models/records.dart';

import 'helpers.dart';

/// IST wall clock (UTC+5:30) without depending on the test machine's zone.
DateTime ist(DateTime utc) {
  final x = utc.toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(x.year, x.month, x.day, x.hour, x.minute);
}

LedgerEntry _e(
  String id,
  DateTime utc, {
  int amount = 10000,
  int paid = 10000,
  PaymentMode mode = PaymentMode.cash,
}) => LedgerEntry(
  id: id,
  collectorUid: 'u',
  type: LedgerType.manual,
  amountPaise: amount,
  paidPaise: paid,
  paymentMode: mode,
  createdAt: utc,
);

Confirmation _c(String handoverId, {int amount = 42000, int paid = 42000}) =>
    Confirmation(
      handoverId: handoverId,
      collectorUid: 'u',
      recyclerId: 'r',
      confirmedAt: DateTime.utc(2026, 10, 26, 5),
      measuredWeightGrams: 2000,
      amountPaise: amount,
      paidPaise: paid,
      paymentMode: paid == 0 ? PaymentMode.due : PaymentMode.cash,
    );

void main() {
  // Monday 26 Oct 2026, 10:00 IST.
  final now = DateTime(2026, 10, 26, 10);

  test('today: paid and due add up in paise', () {
    final s = LedgerSummary.compute(
      [
        _e('a', DateTime.utc(2026, 10, 26, 3), amount: 44000, paid: 44000),
        _e('b', DateTime.utc(2026, 10, 26, 4), amount: 40000, paid: 20000),
        _e('c', DateTime.utc(2026, 10, 26, 4, 1), amount: 33, paid: 0),
      ],
      now,
      toLocal: ist,
    );
    expect(s.todayPaidPaise, 64000); // "Aaj 640 rupaye mile"
    expect(s.todayDuePaise, 20033); // "200 rupaye baaki" (+ 33 paise)
  });

  test('day boundary is local midnight, not UTC midnight', () {
    // 25 Oct 19:00 UTC = 26 Oct 00:30 IST -> today.
    // 25 Oct 18:00 UTC = 25 Oct 23:30 IST -> yesterday.
    final s = LedgerSummary.compute(
      [
        _e('today', DateTime.utc(2026, 10, 25, 19), paid: 100),
        _e('yday', DateTime.utc(2026, 10, 25, 18), paid: 1),
      ],
      now,
      toLocal: ist,
    );
    expect(s.todayPaidPaise, 100);
  });

  test('week starts Monday 00:00 local', () {
    final sunday = DateTime(2026, 11, 1, 22); // Sunday night IST
    final s = LedgerSummary.compute(
      [
        _e('mon', DateTime.utc(2026, 10, 25, 19), paid: 100), // Mon 00:30 IST
        _e(
          'sun-before',
          DateTime.utc(2026, 10, 25, 18),
          paid: 1,
        ), // Sun 23:30 IST
        _e('sat', DateTime.utc(2026, 10, 31, 6), paid: 1000),
      ],
      sunday,
      toLocal: ist,
    );
    expect(s.weekPaidPaise, 1100);
  });

  test('money due is counted from every day, never negative', () {
    final s = LedgerSummary.compute(
      [
        _e('old', DateTime.utc(2026, 9, 1), amount: 50000, paid: 0),
        _e('over', DateTime.utc(2026, 10, 26, 4), amount: 100, paid: 200),
      ],
      now,
      toLocal: ist,
    );
    expect(s.totalDuePaise, 50000);
  });

  test('empty ledger is all zero', () {
    final s = LedgerSummary.compute(const [], now);
    expect(
      [s.todayPaidPaise, s.todayDuePaise, s.weekPaidPaise, s.totalDuePaise],
      [0, 0, 0, 0],
    );
  });

  group('merge', () {
    test('a confirmation becomes one handover entry with a fixed id', () {
      final e = entryFromConfirmation(_c('h1', paid: 0), materialCode: 'PCB');
      expect(e.id, 'h_h1');
      expect(e.type, LedgerType.handover);
      expect(e.duePaise, 42000);
      expect(e.materialCode, 'PCB');
    });

    test('no duplicates when the entry is already saved', () {
      final merged = mergeLedger(
        [entryFromConfirmation(_c('h1'))],
        [_c('h1'), _c('h2')],
      );
      expect(merged.map((e) => e.id).toSet(), {'h_h1', 'h_h2'});
      expect(merged, hasLength(2));
    });

    test('newest first', () {
      final merged = mergeLedger([
        _e('old', DateTime.utc(2026, 1, 1)),
        _e('new', DateTime.utc(2026, 12, 1)),
      ], const []);
      expect(merged.first.id, 'new');
    });
  });

  testWidgets('screen: due shown separately, summary is spoken', (
    tester,
  ) async {
    phoneScreen(tester);
    final audio = FakeAudio();
    final now = DateTime.now().toUtc();
    await tester.pumpWidget(
      testApp(
        const LedgerScreen(),
        prefs: await freshPrefs({'language': 'en'}),
        audio: audio,
        overrides: [
          mySavedLedgerProvider.overrideWith(
            (ref) =>
                Stream.value([_e('cash', now, amount: 44000, paid: 44000)]),
          ),
          myConfirmationsProvider.overrideWith(
            (ref) => Stream.value({
              'h9': Confirmation(
                handoverId: 'h9',
                collectorUid: 'u',
                recyclerId: 'r',
                confirmedAt: now,
                measuredWeightGrams: 1000,
                amountPaise: 20000,
                paidPaise: 0,
                paymentMode: PaymentMode.due,
              ),
            }),
          ),
          myHandoversProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total still due'), findsOneWidget);
    expect(find.text('₹440'), findsWidgets); // got today
    expect(find.text('Later ₹200'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsWidgets);
    expect(audio.spoken.first, 'ledger_summary');
  });
}
