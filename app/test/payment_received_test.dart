import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/hash/handover_hasher.dart';
import 'package:kabadiwala_connect/core/ledger/deal_status.dart';
import 'package:kabadiwala_connect/data/models/records.dart';
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

Confirmation _c(String id, {List<String> flags = const [], int hour = 5}) =>
    Confirmation(
      handoverId: id,
      collectorUid: 'uid-1',
      recyclerId: 'rec_a',
      confirmedAt: DateTime.utc(2026, 10, 25, hour),
      measuredWeightGrams: 2000,
      amountPaise: 42000,
      paidPaise: 42000,
      paymentMode: PaymentMode.cash,
      flags: flags,
    );

Receipt _r(String id, bool received) =>
    receiptFor(_c(id), received: received, at: DateTime.utc(2026, 10, 25, 6));

Future<FakeAudio> _receiptScreen(
  WidgetTester tester, {
  Confirmation? confirmation,
  Receipt? receipt,
}) async {
  phoneScreen(tester);
  final audio = FakeAudio();
  await tester.pumpWidget(
    testApp(
      HandoverScreen(handover: _h, recyclerName: 'Recycler A'),
      prefs: await freshPrefs({'language': 'en'}),
      audio: audio,
      overrides: [
        myConfirmationsProvider.overrideWith(
          (ref) => Stream.value({'h-1': ?confirmation}),
        ),
        myReceiptsProvider.overrideWith(
          (ref) => Stream.value({'h-1': ?receipt}),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
  return audio;
}

void main() {
  group('deal stage', () {
    test('needs the recycler, then the collector\'s "yes"', () {
      expect(dealStage(null, null), DealStage.waitingRecycler);
      expect(dealStage(_c('a'), null), DealStage.waitingCollector);
      expect(dealStage(_c('a'), _r('a', false)), DealStage.notReceived);
      expect(dealStage(_c('a'), _r('a', true)), DealStage.complete);
    });

    test('a changed record is disputed whatever the answer', () {
      final bad = _c('a', flags: const ['hash_mismatch']);
      expect(dealStage(bad, _r('a', true)), DealStage.disputed);
    });

    test('receipt copies the deal and the amount paid', () {
      final r = _r('a', true);
      expect(r.toMap()['received'], isTrue);
      expect(r.amountPaise, 42000);
      expect(r.recyclerId, 'rec_a');
      expect(Receipt.fromMap('a', r.toMap()).received, isTrue);
    });

    test('only unanswered or "not received" deals are asked, oldest first', () {
      final list = awaitingAnswer(
        [_c('new', hour: 9), _c('old', hour: 1), _c('done'), _c('no')],
        {'done': _r('done', true), 'no': _r('no', false)},
      );
      expect(list.map((c) => c.handoverId), ['old', 'no', 'new']);
    });
  });

  testWidgets('collector is asked "did you get the money?" with Yes / No', (
    tester,
  ) async {
    final audio = await _receiptScreen(tester, confirmation: _c('h-1'));
    expect(find.text('Did you get the money?'), findsOneWidget);
    expect(find.text('₹420 · Cash'), findsOneWidget);
    expect(find.text('Yes, got it'), findsOneWidget);
    expect(find.text('Not received'), findsOneWidget);
    expect(find.text('Confirmed'), findsNothing);
    expect(audio.spoken, contains('payment_question'));

    await tester.tap(find.text('Yes, got it'));
    await tester.pump();
    expect(audio.spoken.last, 'payment_received_done');
  });

  testWidgets('after "yes" the receipt is green and complete', (tester) async {
    await _receiptScreen(
      tester,
      confirmation: _c('h-1'),
      receipt: _r('h-1', true),
    );
    expect(find.text('Complete, money received'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Yes, got it'), findsNothing);
  });

  testWidgets('after "no" it stays red and only Yes is offered', (
    tester,
  ) async {
    await _receiptScreen(
      tester,
      confirmation: _c('h-1'),
      receipt: _r('h-1', false),
    );
    expect(find.text('Kabadiwala says money not received'), findsOneWidget);
    expect(find.text('Yes, got it'), findsOneWidget);
    expect(find.text('Not received'), findsNothing);
  });

  testWidgets('recycler can only pay now: Cash or UPI, no "Later"', (
    tester,
  ) async {
    phoneScreen(tester);
    await tester.pumpWidget(
      testApp(
        VerifyScreen(payload: HandoverHasher.qrPayload(_h)),
        prefs: await freshPrefs({
          'language': 'en',
          'role': 'recycler',
          'recycler_id': 'rec_a',
        }),
        audio: FakeAudio(),
      ),
    );
    await tester.pump();
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(jsonDecode(HandoverHasher.qrPayload(_h))['id'], 'h-1');
  });
}
