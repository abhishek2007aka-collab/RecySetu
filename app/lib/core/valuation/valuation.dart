import '../../data/models/catalog.dart';

/// A fair-price estimate for one lot (PLAN.md §6.1). All money in paise.
class Estimate {
  const Estimate({
    required this.lowPaise,
    required this.highPaise,
    required this.spokenRupees,
  });

  final int lowPaise;
  final int highPaise;

  /// Middle of the range, rounded to the nearest ₹10 — the one number we say.
  final int spokenRupees;
}

abstract final class Valuation {
  /// weight (g) × rate (paise/kg) ÷ 1000, rounded half up. Integers only.
  static int paiseFor(int weightGrams, int paisePerKg) =>
      (weightGrams * paisePerKg + 500) ~/ 1000;

  static Estimate estimate(int weightGrams, Price price) {
    final low = paiseFor(weightGrams, price.lowPaisePerKg);
    final high = paiseFor(weightGrams, price.highPaisePerKg);
    // mid = (low + high) / 2 paise; nearest ₹10 = nearest 1000 paise.
    // Using low + high (= 2 × mid) keeps everything in whole numbers.
    final tens = (low + high + 1000) ~/ 2000;
    return Estimate(lowPaise: low, highPaise: high, spokenRupees: tens * 10);
  }
}
