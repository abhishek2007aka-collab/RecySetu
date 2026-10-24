/// Number formatting for display. Integers only: no floating-point money.
abstract final class Fmt {
  /// Indian digit grouping: 150000 -> "1,50,000".
  static String indian(int n) {
    if (n < 0) return '-${indian(-n)}';
    final s = '$n';
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  /// Paise -> "₹1,340" (whole rupees, rounded half up).
  static String rupees(int paise) => '₹${indian((paise + 50) ~/ 100)}';

  /// Grams -> kilos with at most one decimal: 2500 -> "2.5", 3000 -> "3".
  static String kg(int grams) {
    final whole = grams ~/ 1000;
    final tenth = (grams % 1000 + 50) ~/ 100;
    if (tenth == 0) return indian(whole);
    if (tenth == 10) return indian(whole + 1);
    return '${indian(whole)}.$tenth';
  }
}
