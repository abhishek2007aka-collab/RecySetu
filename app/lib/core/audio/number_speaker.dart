/// Turns a rupee amount into recorded clip names for languages without
/// Android TTS (PLAN.md §6.6). Clips live at `assets/audio/<lang>/<name>.mp3`.
///
/// Indian grouping: lakh, thousand, hundred, then 0..99 (each 0..99 is its
/// own clip because Hindi-family number names are irregular).
/// Example: 1340 -> num/1, thousand, num/3, hundred, num/40.
abstract final class NumberSpeaker {
  /// Clips for "about [rupees] rupees".
  static List<String> clipsForRupees(int rupees) => [
    'about',
    ...clipsForNumber(rupees),
    'rupees',
  ];

  static List<String> clipsForNumber(int n) {
    if (n < 0) throw ArgumentError.value(n, 'n', 'must not be negative');
    if (n == 0) return const ['num/0'];

    final parts = <String>[];
    final lakhs = n ~/ 100000;
    final thousands = (n % 100000) ~/ 1000;
    final hundreds = (n % 1000) ~/ 100;
    final rest = n % 100;

    // Above 99 lakh (1 crore+) the lakh count is itself spoken as a number.
    if (lakhs > 0) parts.addAll([...clipsForNumber(lakhs), 'lakh']);
    if (thousands > 0) parts.addAll(['num/$thousands', 'thousand']);
    if (hundreds > 0) parts.addAll(['num/$hundreds', 'hundred']);
    if (rest > 0) parts.add('num/$rest');
    return parts;
  }
}
