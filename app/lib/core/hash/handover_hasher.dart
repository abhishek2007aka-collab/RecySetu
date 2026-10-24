import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data/models/records.dart';

/// Tamper-evident handover reference (PLAN.md §6.4).
///
/// The hash proves the record was not changed after it was created. It is
/// not a legal signature: anyone with the app could make a new record, but
/// nobody can change an existing one without the hash showing it.
abstract final class HandoverHasher {
  static String _sha(String s) => sha256.convert(utf8.encode(s)).toString();

  /// Rounds a coordinate to 5 decimals (about 1 m) so the same value is
  /// written, shown in the QR and re-hashed on every phone.
  static double round5(double v) => double.parse(v.toStringAsFixed(5));

  /// sha256 of the photo hashes, sorted then joined (order-independent).
  static String photosHash(List<String> photoHashes) =>
      _sha((List.of(photoHashes)..sort()).join());

  static String canonical({
    required String id,
    required String collectorUid,
    required String recyclerId,
    required String materialCode,
    required int weightGrams,
    required int agreedPaise,
    required int createdAtEpochSeconds,
    required double lat,
    required double lng,
    required String photosHash,
  }) => [
    'v1',
    id,
    collectorUid,
    recyclerId,
    materialCode,
    weightGrams,
    agreedPaise,
    createdAtEpochSeconds,
    lat.toStringAsFixed(5),
    lng.toStringAsFixed(5),
    photosHash,
  ].join('|');

  static String hashOf(Handover h) => _sha(
    canonical(
      id: h.id,
      collectorUid: h.collectorUid,
      recyclerId: h.recyclerId,
      materialCode: h.materialCode,
      weightGrams: h.weightGrams,
      agreedPaise: h.agreedPaise,
      createdAtEpochSeconds: h.createdAt.millisecondsSinceEpoch ~/ 1000,
      lat: h.lat,
      lng: h.lng,
      photosHash: h.photosHash,
    ),
  );

  /// Builds a sealed handover. Time is cut to whole seconds and the
  /// location to 5 decimals so the QR can reproduce the hash exactly.
  static Handover create({
    required String id,
    required String lotId,
    required String collectorUid,
    required String recyclerId,
    required String materialCode,
    required int weightGrams,
    required int agreedPaise,
    required DateTime createdAt,
    required double lat,
    required double lng,
    required List<String> photoHashes,
  }) {
    final seconds = createdAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    final unsealed = Handover(
      id: id,
      lotId: lotId,
      collectorUid: collectorUid,
      recyclerId: recyclerId,
      materialCode: materialCode,
      weightGrams: weightGrams,
      agreedPaise: agreedPaise,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      ),
      lat: round5(lat),
      lng: round5(lng),
      photosHash: photosHash(photoHashes),
      hash: '',
    );
    return Handover(
      id: unsealed.id,
      lotId: unsealed.lotId,
      collectorUid: unsealed.collectorUid,
      recyclerId: unsealed.recyclerId,
      materialCode: unsealed.materialCode,
      weightGrams: unsealed.weightGrams,
      agreedPaise: unsealed.agreedPaise,
      createdAt: unsealed.createdAt,
      lat: unsealed.lat,
      lng: unsealed.lng,
      photosHash: unsealed.photosHash,
      hash: hashOf(unsealed),
    );
  }

  /// Compact JSON for the QR code.
  static String qrPayload(Handover h) => jsonEncode({
    'v': 1,
    'id': h.id,
    'c': h.collectorUid,
    'r': h.recyclerId,
    'm': h.materialCode,
    'w': h.weightGrams,
    'a': h.agreedPaise,
    't': h.createdAt.millisecondsSinceEpoch ~/ 1000,
    'la': h.lat,
    'lo': h.lng,
    'ph': h.photosHash,
    'h': h.hash,
  });

  /// "a3f91c2b..." -> "A3F9-1C2B", easy to read out over the phone.
  static String shortRef(String hash) {
    final s = hash.substring(0, 8).toUpperCase();
    return '${s.substring(0, 4)}-${s.substring(4)}';
  }

  /// Reads a QR payload back into a handover (the `hash` field is the one
  /// written in the QR). Returns null if it is not one of our QR codes.
  static Handover? parse(String payload) {
    try {
      final m = jsonDecode(payload) as Map<String, dynamic>;
      if (m['v'] != 1) return null;
      return Handover(
        id: m['id'] as String,
        lotId: '',
        collectorUid: m['c'] as String,
        recyclerId: m['r'] as String,
        materialCode: m['m'] as String,
        weightGrams: m['w'] as int,
        agreedPaise: m['a'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (m['t'] as int) * 1000,
          isUtc: true,
        ),
        lat: (m['la'] as num).toDouble(),
        lng: (m['lo'] as num).toDouble(),
        photosHash: m['ph'] as String,
        hash: m['h'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// True when the fields still produce the hash written in the QR.
  static bool verify(Handover fromQr) => hashOf(fromQr) == fromQr.hash;
}
