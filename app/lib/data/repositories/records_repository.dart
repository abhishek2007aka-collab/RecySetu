import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/records.dart';

/// Lots, handovers, confirmations, ledger entries and user profiles.
///
/// Writes are fire-and-forget on purpose: Firestore saves them to the phone
/// at once and sends them when internet returns. `await`ing a write would
/// wait until the server answers, which never happens offline.
/// Document IDs come from the device, so repeating a write is harmless.
class RecordsRepository {
  RecordsRepository(this._db);

  final FirebaseFirestore _db;

  void saveUser(AppUser user) => _write('users', user.uid, user.toMap());
  void saveLot(Lot lot) => _write('lots', lot.id, lot.toMap());
  void saveHandover(Handover h) => _write('handovers', h.id, h.toMap());
  void saveConfirmation(Confirmation c) =>
      _write('confirmations', c.handoverId, c.toMap());
  void saveLedgerEntry(LedgerEntry e) => _write('ledger', e.id, e.toMap());

  /// Small photo thumbnail stored as `lots/{lotId}/photos/{index}`.
  void savePhotoThumb({
    required String lotId,
    required int index,
    required String collectorUid,
    required String sha256Hex,
    required String thumbBase64,
  }) => _write('lots/$lotId/photos', '$index', {
    'collectorUid': collectorUid,
    'sha256': sha256Hex,
    'jpegBase64': thumbBase64,
  });

  /// An invited recycler links their login to their listing (allowed by
  /// firestore.rules only when the phone number matches `ownerPhone`).
  void claimRecycler(String recyclerId, String uid) =>
      _write('recyclers', recyclerId, {'ownerUid': uid});

  Stream<AppUser?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromMap(uid, d.data()!) : null);

  Stream<List<Lot>> watchLots(String collectorUid) =>
      _mine('lots', collectorUid, Lot.fromMap);

  Stream<List<Handover>> watchHandovers(String collectorUid) =>
      _mine('handovers', collectorUid, Handover.fromMap);

  Stream<List<Confirmation>> watchConfirmations(String collectorUid) =>
      _mine('confirmations', collectorUid, Confirmation.fromMap);

  Stream<List<LedgerEntry>> watchLedger(String collectorUid) =>
      _mine('ledger', collectorUid, LedgerEntry.fromMap);

  /// Confirmations a recycler has written (recycler mode, R1).
  Stream<List<Confirmation>> watchRecyclerConfirmations(String recyclerId) =>
      _db
          .collection('confirmations')
          .where('recyclerId', isEqualTo: recyclerId)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs) Confirmation.fromMap(d.id, d.data()),
            ],
          );

  /// True while this collector's lots have writes not yet on the server.
  /// Used by the sync icon.
  Stream<bool> watchHasPendingWrites(String collectorUid) => _db
      .collection('lots')
      .where('collectorUid', isEqualTo: collectorUid)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.metadata.hasPendingWrites);

  Stream<List<T>> _mine<T>(
    String collection,
    String collectorUid,
    T Function(String id, Map<String, dynamic>) fromMap,
  ) => _db
      .collection(collection)
      .where('collectorUid', isEqualTo: collectorUid)
      .snapshots()
      .map((s) => [for (final d in s.docs) fromMap(d.id, d.data())]);

  void _write(String collection, String id, Map<String, dynamic> data) {
    _db
        .collection(collection)
        .doc(id)
        .set(data, SetOptions(merge: true))
        .catchError((Object e) => debugPrint('write $collection/$id: $e'));
  }
}
