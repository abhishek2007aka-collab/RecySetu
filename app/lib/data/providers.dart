import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_providers.dart';
import 'models/catalog.dart';
import 'models/records.dart';
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

final firebaseAuthProvider = Provider<FirebaseAuth?>(
  (ref) => ref.watch(firebaseReadyProvider) ? FirebaseAuth.instance : null,
);

/// The signed-in Firebase user. Firebase keeps this on the phone, so it is
/// available offline after the first login.
final authUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth == null ? Stream.value(null) : auth.authStateChanges();
});

final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authUserProvider).value?.uid,
);

/// True while this collector has writes not yet on the server.
final pendingWritesProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(recordsRepositoryProvider);
  final uid = ref.watch(currentUidProvider);
  if (repo == null || uid == null) return Stream.value(false);
  return repo.watchHasPendingWrites(uid);
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

/// Recycler confirmations for this collector, by handover id.
final myConfirmationsProvider = StreamProvider<Map<String, Confirmation>>((
  ref,
) {
  final repo = ref.watch(recordsRepositoryProvider);
  final uid = ref.watch(currentUidProvider);
  if (repo == null || uid == null) return Stream.value(const {});
  return repo
      .watchConfirmations(uid)
      .map((list) => {for (final c in list) c.handoverId: c});
});

/// This collector's handovers.
final myHandoversProvider = StreamProvider<List<Handover>>((ref) {
  final repo = ref.watch(recordsRepositoryProvider);
  final uid = ref.watch(currentUidProvider);
  if (repo == null || uid == null) return Stream.value(const []);
  return repo.watchHandovers(uid);
});
