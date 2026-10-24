import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/hash/handover_hasher.dart';
import '../../core/sync/photo_store.dart';
import '../../core/valuation/valuation.dart';
import '../../core/vision/scrap_classifier.dart';
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
    this.handover,
    this.photoScores = const [],
  }) : lotId = lotId ?? const Uuid().v4();

  /// Made on the phone at the start, so saving twice never makes two lots.
  final String lotId;
  final List<LocalPhoto> photos;
  final String? materialCode;
  final int weightGrams;
  final bool saved;

  /// Set once the collector chose a recycler and the record was sealed.
  final Handover? handover;

  /// Recogniser scores per photo (empty when no model is bundled).
  final List<Map<String, double>> photoScores;

  static const maxPhotos = 3;
  static const maxWeightGrams = 1000 * 1000; // 1 tonne

  SellDraft copyWith({
    List<LocalPhoto>? photos,
    String? materialCode,
    int? weightGrams,
    bool? saved,
    Handover? handover,
    List<Map<String, double>>? photoScores,
  }) => SellDraft(
    lotId: lotId,
    photos: photos ?? this.photos,
    materialCode: materialCode ?? this.materialCode,
    weightGrams: weightGrams ?? this.weightGrams,
    saved: saved ?? this.saved,
    handover: handover ?? this.handover,
    photoScores: photoScores ?? this.photoScores,
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

  void removePhoto(LocalPhoto p) {
    final i = state.photos.indexOf(p);
    if (i < 0) return;
    state = state.copyWith(
      photos: [...state.photos]..removeAt(i),
      photoScores: i < state.photoScores.length
          ? ([...state.photoScores]..removeAt(i))
          : state.photoScores,
    );
  }

  /// Runs the recogniser on a new photo (if a model is bundled).
  Future<void> classify(LocalPhoto p) async {
    final classifier = await ref.read(scrapClassifierProvider.future);
    if (classifier == null) return;
    try {
      final scores = await classifier.classify(p.path);
      if (!state.photos.contains(p)) return;
      state = state.copyWith(photoScores: [...state.photoScores, scores]);
    } catch (e) {
      debugPrint('classify: $e');
    }
  }

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

  /// Seals the handover for [recyclerId] (PLAN.md §6.4), saves it offline
  /// and marks the lot as handed over. Choosing the same recycler again
  /// reuses the same record.
  Handover? handOver({
    required String collectorUid,
    required String recyclerId,
    required int agreedPaise,
    required double lat,
    required double lng,
  }) {
    final existing = state.handover;
    if (existing != null && existing.recyclerId == recyclerId) return existing;
    final code = state.materialCode;
    final repo = ref.read(recordsRepositoryProvider);
    if (code == null || repo == null) return null;
    final h = HandoverHasher.create(
      id: const Uuid().v4(),
      lotId: state.lotId,
      collectorUid: collectorUid,
      recyclerId: recyclerId,
      materialCode: code,
      weightGrams: state.weightGrams,
      agreedPaise: agreedPaise,
      createdAt: DateTime.now(),
      lat: lat,
      lng: lng,
      photoHashes: [for (final p in state.photos) p.sha256Hex],
    );
    repo.saveHandover(h);
    repo.setLotStatus(state.lotId, collectorUid, LotStatus.handedOver);
    state = state.copyWith(handover: h);
    return h;
  }
}

final sellDraftProvider = NotifierProvider<SellDraftNotifier, SellDraft>(
  SellDraftNotifier.new,
);

/// The bundled recogniser, or null when the team has not added a model.
final scrapClassifierProvider = FutureProvider<ScrapClassifier?>((ref) async {
  final c = await ScrapClassifier.load();
  ref.onDispose(() => c?.close());
  return c;
});

/// What the recogniser thinks this lot is, if it is sure enough (≥ 70%).
final draftSuggestionProvider = Provider<Suggestion?>((ref) {
  final scores = ref.watch(sellDraftProvider.select((d) => d.photoScores));
  final codes = {
    for (final m
        in ref.watch(materialsProvider).value ?? const <ScrapMaterial>[])
      m.code,
  };
  return pickSuggestion(scores, codes);
});

/// The material behind the suggestion, once materials have loaded.
final suggestedMaterialProvider = Provider<ScrapMaterial?>((ref) {
  final code = ref.watch(draftSuggestionProvider)?.materialCode;
  if (code == null) return null;
  return (ref.watch(materialsProvider).value ?? const <ScrapMaterial>[])
      .where((m) => m.code == code)
      .firstOrNull;
});

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
