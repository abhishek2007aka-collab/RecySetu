import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_providers.dart';
import 'models/catalog.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/records_repository.dart';
import 'seed/seed_loader.dart';

/// Null when Firebase failed to start; the app then runs on seed data only.
final firestoreProvider = Provider<FirebaseFirestore?>(
  (ref) => ref.watch(firebaseReadyProvider) ? FirebaseFirestore.instance : null,
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(firestoreProvider), SeedLoader()),
);

final recordsRepositoryProvider = Provider<RecordsRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : RecordsRepository(db);
});

final materialsProvider = StreamProvider<List<ScrapMaterial>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchMaterials(),
);

final pricesProvider = StreamProvider<List<Price>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchPrices(),
);

final recyclersProvider = StreamProvider<List<Recycler>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchRecyclers(),
);

final areasProvider = StreamProvider<List<Area>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchAreas(),
);
