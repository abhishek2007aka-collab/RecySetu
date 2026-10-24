import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/hash/anomaly_flags.dart';
import 'package:kabadiwala_connect/core/hash/handover_hasher.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';
import 'package:kabadiwala_connect/data/models/records.dart';

Handover _make({
  String id = 'h-1',
  String recyclerId = 'rec_a',
  int weightGrams = 2500,
  int agreedPaise = 52500,
  double lat = 29.854312345,
  List<String> photos = const ['bb', 'aa'],
  DateTime? at,
}) => HandoverHasher.create(
  id: id,
  lotId: 'lot-1',
  collectorUid: 'uid-1',
  recyclerId: recyclerId,
  materialCode: 'PCB',
  weightGrams: weightGrams,
  agreedPaise: agreedPaise,
  createdAt: at ?? DateTime.utc(2026, 10, 24, 12, 0, 0, 750),
  lat: lat,
  lng: 77.888,
  photoHashes: photos,
);

void main() {
  group('hash (§6.4)', () {
    test('same input gives the same hash', () {
      expect(_make().hash, _make().hash);
      expect(_make().hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('changing any field changes the hash', () {
      final base = _make().hash;
      expect(_make(id: 'h-2').hash, isNot(base));
      expect(_make(recyclerId: 'rec_b').hash, isNot(base));
      expect(_make(weightGrams: 2501).hash, isNot(base));
      expect(_make(agreedPaise: 52501).hash, isNot(base));
      expect(_make(lat: 29.86).hash, isNot(base));
      expect(_make(photos: const ['aa']).hash, isNot(base));
      expect(_make(at: DateTime.utc(2026, 10, 24, 12, 0, 1)).hash, isNot(base));
    });

    test('photo order does not matter; milliseconds are dropped', () {
      expect(_make(photos: const ['aa', 'bb']).hash, _make().hash);
      expect(_make(at: DateTime.utc(2026, 10, 24, 12)).hash, _make().hash);
    });

    test('canonical string follows the spec exactly', () {
      expect(
        HandoverHasher.canonical(
          id: 'i',
          collectorUid: 'c',
          recyclerId: 'r',
          materialCode: 'PCB',
          weightGrams: 2500,
          agreedPaise: 52500,
          createdAtEpochSeconds: 1792843200,
          lat: 29.8543,
          lng: 77.888,
          photosHash: 'p',
        ),
        'v1|i|c|r|PCB|2500|52500|1792843200|29.85430|77.88800|p',
      );
    });

    test('short reference is 8 upper-case chars split 4-4', () {
      expect(HandoverHasher.shortRef('a3f91c2b${'0' * 56}'), 'A3F9-1C2B');
    });
  });

  group('QR round trip', () {
    test('a genuine QR verifies', () {
      final h = _make();
      final back = HandoverHasher.parse(HandoverHasher.qrPayload(h))!;
      expect(HandoverHasher.verify(back), isTrue);
      expect(back.weightGrams, h.weightGrams);
      expect(back.hash, h.hash);
    });

    test('a tampered QR (weight changed) fails', () {
      final m = jsonDecode(HandoverHasher.qrPayload(_make())) as Map;
      m['w'] = 5000;
      final back = HandoverHasher.parse(jsonEncode(m))!;
      expect(HandoverHasher.verify(back), isFalse);
    });

    test('a tampered QR (price changed) fails', () {
      final m = jsonDecode(HandoverHasher.qrPayload(_make())) as Map;
      m['a'] = 99999;
      expect(
        HandoverHasher.verify(HandoverHasher.parse(jsonEncode(m))!),
        isFalse,
      );
    });

    test('random QR codes are rejected', () {
      expect(HandoverHasher.parse('https://example.com'), isNull);
      expect(HandoverHasher.parse('{"v":2}'), isNull);
      expect(HandoverHasher.parse('{"v":1,"id":3}'), isNull);
    });
  });

  group('anomaly flags (§6.5)', () {
    test('weight mismatch above 10% only', () {
      expect(AnomalyFlags.isWeightMismatch(1000, 1100), isFalse); // exactly 10%
      expect(AnomalyFlags.isWeightMismatch(1000, 1101), isTrue);
      expect(AnomalyFlags.isWeightMismatch(1000, 899), isTrue);
      expect(AnomalyFlags.isWeightMismatch(1000, 900), isFalse);
    });

    test('price outlier outside 0.7 × low .. 1.3 × high', () {
      const board = Price(
        materialCode: 'PCB',
        lowPaisePerKg: 18000,
        highPaisePerKg: 22000,
      );
      // 1 kg: low ₹180, high ₹220 -> allowed ₹126 .. ₹286
      expect(AnomalyFlags.isPriceOutlier(1000, 12600, board), isFalse);
      expect(AnomalyFlags.isPriceOutlier(1000, 12599, board), isTrue);
      expect(AnomalyFlags.isPriceOutlier(1000, 28600, board), isFalse);
      expect(AnomalyFlags.isPriceOutlier(1000, 28601, board), isTrue);
    });

    test('paid amount follows the measured weight', () {
      expect(AnomalyFlags.paidForMeasured(52500, 2500, 2500), 52500);
      expect(AnomalyFlags.paidForMeasured(52500, 2500, 2400), 50400);
      expect(AnomalyFlags.paidForMeasured(52500, 0, 2400), 0);
    });

    test('flags combine', () {
      expect(
        AnomalyFlags.forConfirmation(
          hashOk: false,
          declaredGrams: 1000,
          measuredGrams: 1500,
          agreedPaise: 20000,
        ),
        ['hash_mismatch', 'weight_mismatch'],
      );
    });
  });
}
