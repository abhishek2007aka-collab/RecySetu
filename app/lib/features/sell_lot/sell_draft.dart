import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/photo_store.dart';
import '../../core/valuation/valuation.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';

/// The lot being sold, across screens S6-S9.
class SellDraft {
  SellDraft({
    String? lotId,
    this.photos = const [],
    this.materialCode,
    this.weightGrams = 1000,
    this.saved = false,
  }) : lotId = lotId ?? const Uuid().v4();

  /// Made on the phone at the start, so saving twice never makes two lots.
  final String lotId;
  final List<LocalPhoto> photos;
  final String? materialCode;
  final int weightGrams;
  final bool saved;

  static const maxPhotos = 3;
  static const maxWeightGrams = 1000 * 1000; // 1 tonne

  SellDraft copyWith({
    List<LocalPhoto>? photos,
    String? materialCode,
    int? weightGrams,
    bool? saved,
  }) => SellDraft(
    lotId: lotId,
    photos: photos ?? this.photos,
    materialCode: materialCode ?? this.materialCode,
    weightGrams: weightGrams ?? this.weightGrams,
    saved: saved ?? this.saved,
  );
}

class SellDraftNotifier extends Notifier<SellDraft> {
  @override
  SellDraft build() => SellDraft();

  void start() => state = SellDraft();

  void addPhoto(LocalPhoto p) {
    if (state.photos.length >= SellDraft.maxPhotos) return;
    state = state.copyWith(photos: [...state.photos, p]);
  }

  void removePhoto(LocalPhoto p) =>
      state = state.copyWith(photos: [...state.photos]..remove(p));

  void chooseMaterial(String code) =>
      state = state.copyWith(materialCode: code);

  /// Adds [deltaGrams] (may be negative), kept between 0 and 1 tonne.
  void changeWeight(int deltaGrams) =>
      setWeight(state.weightGrams + deltaGrams);

  void setWeight(int grams) => state = state.copyWith(
    weightGrams: grams.clamp(0, SellDraft.maxWeightGrams),
  );

  /// Saves the lot as a draft (offline write) plus its photo thumbnails.
  /// Safe to call more than once: same IDs, same documents.
  Lot? save({required String collectorUid, required Estimate estimate}) {
    final code = state.materialCode;
    final repo = ref.read(recordsRepositoryProvider);
    if (code == null || repo == null) return null;
    final lot = Lot(
      id: state.lotId,
      collectorUid: collectorUid,
      materialCode: code,
      weightGrams: state.weightGrams,
      estLowPaise: estimate.lowPaise,
      estHighPaise: estimate.highPaise,
      createdAt: DateTime.now().toUtc(),
      photoHashes: [for (final p in state.photos) p.sha256Hex],
    );
    repo.saveLot(lot);
    for (final (i, p) in state.photos.indexed) {
      repo.savePhotoThumb(
        lotId: lot.id,
        index: i,
        collectorUid: collectorUid,
        sha256Hex: p.sha256Hex,
        thumbBase64: p.thumbBase64,
      );
    }
    state = state.copyWith(saved: true);
    return lot;
  }
}

final sellDraftProvider = NotifierProvider<SellDraftNotifier, SellDraft>(
  SellDraftNotifier.new,
);

final photoStoreProvider = Provider<PhotoStore>((ref) => PhotoStore());

/// Price for the chosen material, if known.
final draftPriceProvider = Provider<Price?>((ref) {
  final code = ref.watch(sellDraftProvider.select((d) => d.materialCode));
  final prices = ref.watch(pricesProvider).value ?? const <Price>[];
  for (final p in prices) {
    if (p.materialCode == code) return p;
  }
  return null;
});
