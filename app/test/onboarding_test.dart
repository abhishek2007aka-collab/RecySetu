import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/app_gate.dart';
import 'package:kabadiwala_connect/core/app_providers.dart';
import 'package:kabadiwala_connect/core/sync/sync_status.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/features/home/home_screen.dart';
import 'package:kabadiwala_connect/features/onboarding/language_pick_screen.dart';
import 'package:kabadiwala_connect/features/onboarding/login_screen.dart';
import 'package:kabadiwala_connect/features/onboarding/role_screen.dart';
import 'package:kabadiwala_connect/features/onboarding/session.dart';

import 'helpers.dart';

Recycler _recycler(String id, String? ownerPhone) => Recycler(
  id: id,
  name: id,
  phone: '',
  lat: 0,
  lng: 0,
  address: '',
  authorised: true,
  authorisationRef: '',
  offersPickup: false,
  ratesPaisePerKg: const {},
  ownerPhone: ownerPhone,
);

void main() {
  group('PIN', () {
    test('hash is stable, and differs per user and per PIN', () {
      expect(hashPin('u1', '1234'), hashPin('u1', '1234'));
      expect(hashPin('u1', '1234'), isNot(hashPin('u2', '1234')));
      expect(hashPin('u1', '1234'), isNot(hashPin('u1', '1235')));
      expect(hashPin('u1', '1234'), isNot(contains('1234')));
    });

    test('set, survive restart, unlock only with the right PIN', () async {
      final prefs = await freshPrefs();
      var c = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      c.read(sessionProvider.notifier).setPin('u1', '4321');
      expect(c.read(sessionProvider).unlocked, isTrue);
      c.dispose();

      // A cold start: PIN remembered, but locked again.
      c = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      expect(c.read(sessionProvider).pinHash, isNotNull);
      expect(c.read(sessionProvider).unlocked, isFalse);
      expect(c.read(sessionProvider.notifier).unlock('u1', '0000'), isFalse);
      expect(c.read(sessionProvider.notifier).unlock('u1', '4321'), isTrue);
      expect(c.read(sessionProvider).unlocked, isTrue);
      c.dispose();
    });
  });

  test('sync icon rule: offline, then pending, else synced', () {
    expect(syncStateFor(online: false, pendingWrites: true), SyncState.offline);
    expect(syncStateFor(online: true, pendingWrites: true), SyncState.pending);
    expect(syncStateFor(online: true, pendingWrites: false), SyncState.synced);
  });

  test('recycler mode only for an invited phone number', () {
    final all = [_recycler('a', null), _recycler('b', '+919999900002')];
    expect(RoleScreen.invitedRecycler(all, '+919999900002')?.id, 'b');
    expect(RoleScreen.invitedRecycler(all, '+919999900001'), isNull);
    expect(RoleScreen.invitedRecycler(all, ''), isNull);
  });

  testWidgets('fresh install: language pick, double tap chooses, then login', (
    tester,
  ) async {
    phoneScreen(tester);
    final prefs = await freshPrefs();
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(const AppGate(), prefs: prefs, audio: audio),
    );
    await tester.pump();
    expect(find.byType(LanguagePickScreen), findsOneWidget);
    expect(audio.spoken, contains('choose_language'));

    await tester.tap(find.text('मराठी'));
    await tester.pump();
    expect(audio.spoken.last, 'lang_name');
    expect(find.byType(LanguagePickScreen), findsOneWidget);

    await tester.tap(find.text('मराठी'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(prefs.getString('language'), 'mr');
    expect(find.text('तुमचा मोबाईल नंबर टाका'), findsWidgets);
  });

  testWidgets('home has 4 big tiles of at least 56 dp and speaks', (
    tester,
  ) async {
    phoneScreen(tester);
    final prefs = await freshPrefs({'language': 'en'});
    final audio = FakeAudio();
    await tester.pumpWidget(
      testApp(const HomeScreen(), prefs: prefs, audio: audio),
    );
    await tester.pump();
    for (final label in [
      'Sell scrap',
      "Today's rates",
      'My earnings',
      'Safety',
    ]) {
      final size = tester.getSize(
        find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(56), reason: label);
    }
    expect(audio.spoken.first, 'home_instruction');
    await tester.tap(find.text('Sell scrap'));
    await tester.pumpAndSettle();
    expect(audio.spoken, contains('tile_sell'));
  });
}
