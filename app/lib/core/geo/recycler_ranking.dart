import '../../data/models/catalog.dart';
import 'geo.dart';

class RankedRecycler {
  const RankedRecycler({
    required this.recycler,
    required this.distanceKm,
    required this.ratePaisePerKg,
    required this.score,
  });

  final Recycler recycler;
  final double distanceKm;
  final int ratePaisePerKg;
  final double score;
}

/// PLAN.md §6.3. Ranks authorised recyclers for one material:
///   rateScore = rate / best rate
///   distScore = 1 − min(km, 25) / 25
///   score     = 0.45·rate + 0.35·distance + 0.20·pickup
/// Unauthorised recyclers and those with no rate for the material are left
/// out (the whole point is the formal route). Ties: higher rate, then
/// nearer, then id, so the order never jumps around.
List<RankedRecycler> rankRecyclers({
  required List<Recycler> recyclers,
  required String materialCode,
  required LatLng from,
  int limit = 5,
}) {
  final candidates = [
    for (final r in recyclers)
      if (r.authorised && (r.ratesPaisePerKg[materialCode] ?? 0) > 0) r,
  ];
  if (candidates.isEmpty) return const [];

  final best = candidates
      .map((r) => r.ratesPaisePerKg[materialCode]!)
      .reduce((a, b) => a > b ? a : b);

  final ranked = [
    for (final r in candidates)
      () {
        final rate = r.ratesPaisePerKg[materialCode]!;
        final km = haversineKm(from, (lat: r.lat, lng: r.lng));
        final rateScore = rate / best;
        final distScore = 1 - (km < 25 ? km : 25) / 25;
        return RankedRecycler(
          recycler: r,
          distanceKm: km,
          ratePaisePerKg: rate,
          score:
              0.45 * rateScore +
              0.35 * distScore +
              0.20 * (r.offersPickup ? 1 : 0),
        );
      }(),
  ];

  ranked.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byRate = b.ratePaisePerKg.compareTo(a.ratePaisePerKg);
    if (byRate != 0) return byRate;
    final byKm = a.distanceKm.compareTo(b.distanceKm);
    if (byKm != 0) return byKm;
    return a.recycler.id.compareTo(b.recycler.id);
  });
  return ranked.take(limit).toList();
}
