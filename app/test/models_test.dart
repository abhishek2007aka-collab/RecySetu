import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/models/records.dart';
import 'package:kabadiwala_connect/data/repositories/catalog_repository.dart';
import 'package:kabadiwala_connect/data/seed/seed_loader.dart';

List<Map<String, dynamic>> _seed(String name) =>
    (jsonDecode(File('assets/seed/$name.json').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

final _t = DateTime.utc(2026, 10, 24, 12, 30);

void main() {
  group('seed data', () {
    test('materials parse, with hazards', () {
      final all = _seed('materials').map(ScrapMaterial.fromMap).toList();
      expect(all, hasLength(8));
      final crt = all.firstWhere((m) => m.code == 'CRT');
      expect(crt.hazard, Hazard.high);
      expect(crt.safetyCardIds, contains('no_break_crt'));
    });

    test('prices are whole paise, low <= high', () {
      for (final p in _seed('prices').map(Price.fromMap)) {
        expect(p.lowPaisePerKg, greaterThan(0));
        expect(p.lowPaisePerKg, lessThanOrEqualTo(p.highPaisePerKg));
      }
      final pcb = _seed('prices').map(Price.fromMap).first;
      expect(pcb.lowPaisePerKg, 18000); // ₹180 in the CSV
    });

    test('recyclers keep only the rates that exist', () {
      final b = _seed('recyclers')
          .map(Recycler.fromMap)
          .firstWhere((r) => r.id == 'rec_placeholder_b');
      expect(b.ratesPaisePerKg.containsKey('BATTERY_PB'), isFalse);
      expect(b.ratesPaisePerKg['PCB'], 22000);
      expect(b.offersPickup, isFalse);
    });

    test('every seed row is marked as placeholder', () {
      for (final name in ['materials', 'prices', 'recyclers', 'areas']) {
        expect(_seed(name).every((r) => r['placeholder'] == true), isTrue);
      }
    });
  });

  group('records round-trip through toMap/fromMap', () {
    test('Lot keeps handed_over status and Timestamp time', () {
      final lot = Lot(
        id: 'l1',
        collectorUid: 'u1',
        materialCode: 'PCB',
        weightGrams: 2500,
        estLowPaise: 45000,
        estHighPaise: 55000,
        createdAt: _t,
        photoHashes: const ['ab', 'cd'],
        lat: 29.86,
        lng: 77.89,
        status: LotStatus.handedOver,
      );
      final map = lot.toMap();
      expect(map['status'], 'handed_over');
      expect(map['createdAt'], isA<Timestamp>());
      final back = Lot.fromMap('l1', map);
      expect(back.status, LotStatus.handedOver);
      expect(back.createdAt, _t);
      expect(back.photoHashes, ['ab', 'cd']);
      expect(back.weightGrams, 2500);
    });

    test('LedgerEntry uses sold_elsewhere and computes due', () {
      final e = LedgerEntry(
        id: 'e1',
        collectorUid: 'u1',
        type: LedgerType.soldElsewhere,
        amountPaise: 64000,
        paidPaise: 44000,
        paymentMode: PaymentMode.cash,
        createdAt: _t,
      );
      expect(e.toMap()['type'], 'sold_elsewhere');
      final back = LedgerEntry.fromMap('e1', e.toMap());
      expect(back.type, LedgerType.soldElsewhere);
      expect(back.duePaise, 20000);
    });

    test('Confirmation flags hash_mismatch as disputed', () {
      final c = Confirmation(
        handoverId: 'h1',
        collectorUid: 'u1',
        recyclerId: 'r1',
        confirmedAt: _t,
        measuredWeightGrams: 2400,
        paidPaise: 50000,
        paymentMode: PaymentMode.upi,
        flags: const ['hash_mismatch'],
      );
      final back = Confirmation.fromMap('h1', c.toMap());
      expect(back.paymentMode, PaymentMode.upi);
      expect(back.disputed, isTrue);
    });

    test('unknown enum values fall back safely', () {
      final u = AppUser.fromMap('u1', {'role': 'superhero'});
      expect(u.role, UserRole.collector);
      expect(u.language, 'hi');
    });
  });

  test(
    'catalog without Firebase serves seed data (offline first run)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final repo = CatalogRepository(null, SeedLoader());
      final materials = await repo.watchMaterials().first;
      expect(materials.map((m) => m.code), contains('BATTERY_LI'));
    },
  );
}
