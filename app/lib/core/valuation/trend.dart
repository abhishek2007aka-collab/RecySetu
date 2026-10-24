import '../../data/models/catalog.dart';

enum Trend { up, down, flat }

/// PLAN.md §6.2: mid = (low + high) / 2 compared with last week's mid.
/// Up if more than +5%, down if less than −5%, otherwise flat.
/// Integer maths only: we compare (low + high) × 100 with weekAgo × 2 × 105.
Trend trendFor(Price p) {
  final weekAgo = p.weekAgoMidPaisePerKg;
  if (weekAgo == null || weekAgo <= 0) return Trend.flat;
  final mid2x100 = (p.lowPaisePerKg + p.highPaisePerKg) * 100;
  if (mid2x100 > weekAgo * 210) return Trend.up;
  if (mid2x100 < weekAgo * 190) return Trend.down;
  return Trend.flat;
}
