import '../../data/models/catalog.dart';
import '../valuation/valuation.dart';

/// Rule-based warning flags for a confirmed handover (PLAN.md §6.5).
/// Integer maths only.
abstract final class AnomalyFlags {
  static const weightMismatch = 'weight_mismatch';
  static const priceOutlier = 'price_outlier';
  static const hashMismatch = 'hash_mismatch';
  static const hazardUnsafe = 'hazard_unsafe';

  /// |measured − declared| / declared > 10%
  static bool isWeightMismatch(int declaredGrams, int measuredGrams) {
    if (declaredGrams <= 0) return measuredGrams > 0;
    return (measuredGrams - declaredGrams).abs() * 10 > declaredGrams;
  }

  /// Agreed price outside [0.7 × board low, 1.3 × board high] for this weight.
  static bool isPriceOutlier(int weightGrams, int agreedPaise, Price board) {
    final low = Valuation.paiseFor(weightGrams, board.lowPaisePerKg);
    final high = Valuation.paiseFor(weightGrams, board.highPaisePerKg);
    return agreedPaise * 10 < low * 7 || agreedPaise * 10 > high * 13;
  }

  /// What the recycler pays for the weight they measured, at the agreed
  /// rate: agreed × measured ÷ declared, rounded half up.
  static int paidForMeasured(
    int agreedPaise,
    int declaredGrams,
    int measuredGrams,
  ) {
    if (declaredGrams <= 0) return 0;
    return (agreedPaise * measuredGrams + declaredGrams ~/ 2) ~/ declaredGrams;
  }

  static List<String> forConfirmation({
    required bool hashOk,
    required int declaredGrams,
    required int measuredGrams,
    required int agreedPaise,
    Price? board,
  }) => [
    if (!hashOk) hashMismatch,
    if (isWeightMismatch(declaredGrams, measuredGrams)) weightMismatch,
    if (board != null && isPriceOutlier(declaredGrams, agreedPaise, board))
      priceOutlier,
  ];
}
