import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:kabadiwala_connect/features/onboarding/application_status_screen.dart';
import 'package:kabadiwala_connect/features/onboarding/recycler_apply_screen.dart';
import 'package:kabadiwala_connect/features/onboarding/role_screen.dart';

import 'helpers.dart';

Recycler _r(String id, {String? ownerPhone, bool placeholder = false}) =>
    Recycler(
      id: id,
      name: 'Recycler $id',
      phone: '',
      lat: 29.86,
      lng: 77.89,
      address: 'Address $id',
      authorised: true,
      authorisationRef: 'CPCB list $id',
      offersPickup: false,
      ratesPaisePerKg: const {},
      ownerPhone: ownerPhone,
      placeholder: placeholder,
    );

List _recyclers() => [
  recyclersProvider.overrideWith(
    (ref) => Stream.value([
      _r('official'),
      _r('demo', ownerPhone: '+919999900002', placeholder: true),
    ]),
  ),
];

Future<void> _pumpRole(
  WidgetTester tester,
  String phone, {
  required dynamic prefs,
}) async {
  phoneScreen(tester);
  await tester.pumpWidget(
    testApp(
      RoleScreen(uid: 'u1', phone: phone),
      prefs: prefs,
      overrides: _recyclers(),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('everyone is asked: Kabadiwala or Recycler', (tester) async {
    final prefs = await freshPrefs({'language': 'en'});
    await _pumpRole(tester, '+919999900001', prefs: prefs);
    expect(find.text('Collector'), findsOneWidget);
    expect(find.text('Recycler'), findsOneWidget);

    await tester.tap(find.text('Collector'));
    await tester.pump();
    expect(prefs.getString('role'), 'collector');
  });

  testWidgets('invited number: Recycler opens recycler mode', (tester) async {
    final prefs = await freshPrefs({'language': 'en'});
    await _pumpRole(tester, '+919999900002', prefs: prefs);
    await tester.tap(find.text('Recycler'));
    await tester.pump();
    expect(prefs.getString('role'), 'recycler');
    expect(prefs.getString('recycler_id'), 'demo');
  });

  testWidgets(
    'not invited: Recycler opens the apply form, never recycler mode',
    (tester) async {
      final prefs = await freshPrefs({'language': 'en'});
      await _pumpRole(tester, '+919999900001', prefs: prefs);
      await tester.tap(find.text('Recycler'));
      await tester.pumpAndSettle();
      expect(find.byType(RecyclerApplyScreen), findsOneWidget);
      expect(prefs.getString('role'), isNull);

      // Official, unclaimed recyclers are offered; the demo row is not.
      expect(find.text('Recycler official'), findsOneWidget);
      expect(find.text('Recycler demo'), findsNothing);

      final send = find.widgetWithText(FilledButton, 'Send application');
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      await tester.tap(find.text('Recycler official'));
      await tester.pump();
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(prefs.getBool('applied_as_recycler'), isTrue);
      expect(prefs.getString('role'), isNull);
    },
  );

  testWidgets('apply by typing name and registration number', (tester) async {
    phoneScreen(tester);
    final prefs = await freshPrefs({'language': 'en'});
    await tester.pumpWidget(
      testApp(
        const RecyclerApplyScreen(uid: 'u1', phone: '+919999900003'),
        prefs: prefs,
        overrides: _recyclers(),
      ),
    );
    await tester.pump();
    final send = find.widgetWithText(FilledButton, 'Send application');
    await tester.enterText(find.byType(TextField).first, 'Green Recyclers');
    await tester.pump();
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'UKPCB/EW/123');
    await tester.pump();
    expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
  });

  testWidgets('status: pending until the number is linked, then approved', (
    tester,
  ) async {
    phoneScreen(tester);
    final prefs = await freshPrefs({
      'language': 'en',
      'applied_as_recycler': true,
    });
    await tester.pumpWidget(
      testApp(
        const ApplicationStatusScreen(uid: 'u1', phone: '+919999900001'),
        prefs: prefs,
        overrides: _recyclers(),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    expect(find.text('Open recycler mode'), findsNothing);
    await tester.tap(find.text('Use as kabadiwala for now'));
    await tester.pump();
    expect(prefs.getString('role'), 'collector');
    expect(prefs.getBool('applied_as_recycler'), isFalse);
  });

  testWidgets('status: approved number gets the Open recycler mode button', (
    tester,
  ) async {
    phoneScreen(tester);
    final prefs = await freshPrefs({
      'language': 'en',
      'applied_as_recycler': true,
    });
    await tester.pumpWidget(
      testApp(
        const ApplicationStatusScreen(uid: 'u2', phone: '+919999900002'),
        prefs: prefs,
        overrides: _recyclers(),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Open recycler mode'));
    await tester.pump();
    expect(prefs.getString('role'), 'recycler');
  });
}
