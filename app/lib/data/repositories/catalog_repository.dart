import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/catalog.dart';
import '../seed/seed_loader.dart';

/// Materials, prices, recyclers and areas.
///
/// Offline-first: every stream starts with the bundled seed data, then
/// switches to Firestore (cache or server) as soon as Firestore has any
/// documents. Errors (no network, not signed in yet) keep the seed data.
class CatalogRepository {
  CatalogRepository(this._db, this._seed);

  final FirebaseFirestore? _db;
  final SeedLoader _seed;

  Stream<List<ScrapMaterial>> watchMaterials() =>
      _watch('materials', ScrapMaterial.fromMap);

  Stream<List<Price>> watchPrices() => _watch('prices', Price.fromMap);

  Stream<List<Recycler>> watchRecyclers() =>
      _watch('recyclers', Recycler.fromMap);

  Stream<List<Area>> watchAreas() => _watch('areas', Area.fromMap);

  Stream<List<T>> _watch<T>(
    String collection,
    T Function(Map<String, dynamic>) fromMap,
  ) async* {
    final seed = (await _seed.load(collection)).map(fromMap).toList();
    yield seed;

    final db = _db;
    if (db == null) return;
    final snapshots = db
        .collection(collection)
        .snapshots()
        .handleError((Object e) => debugPrint('$collection: $e'));
    await for (final snap in snapshots) {
      if (snap.docs.isEmpty) continue;
      yield [
        for (final doc in snap.docs) fromMap({'id': doc.id, ...doc.data()}),
      ];
    }
  }
}
