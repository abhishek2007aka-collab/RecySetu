import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Big 0-9 keypad with delete and OK, used for phone, OTP, PIN, weight and
/// amounts. Digits are huge so they can be read without reading words.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onOk,
    this.okLabel,
    this.deleteLabel,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;

  /// Null hides/disables the OK key.
  final VoidCallback? onOk;
  final String? okLabel;
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback? onTap, {Color? colour}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 68,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: colour,
              padding: EdgeInsets.zero,
              minimumSize: const Size(AppTheme.minTouch, AppTheme.minTouch),
            ),
            onPressed: onTap,
            child: child,
          ),
        ),
      ),
    );

    Widget digit(int d) => key(
      Text(
        '$d',
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
      ),
      () => onDigit(d),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(children: [for (final d in row) digit(d)]),
        Row(
          children: [
            key(
              Icon(
                Icons.backspace_outlined,
                size: 32,
                semanticLabel: deleteLabel,
              ),
              onDelete,
            ),
            digit(0),
            key(
              Icon(Icons.check, size: 36, semanticLabel: okLabel),
              onOk,
              colour: onOk == null
                  ? null
                  : AppColors.confirmed.withValues(alpha: 0.25),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows entered digits as large boxes (filled dots for a hidden PIN).
class DigitDisplay extends StatelessWidget {
  const DigitDisplay({
    super.key,
    required this.value,
    required this.length,
    this.obscure = false,
  });

  final String value;
  final int length;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < length; i++)
            Container(
              width: 40,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 3,
                    color: i < value.length ? scheme.primary : scheme.outline,
                  ),
                ),
              ),
              child: Text(
                i < value.length ? (obscure ? '●' : value[i]) : '',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
