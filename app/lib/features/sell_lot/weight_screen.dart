import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/valuation/valuation.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../core/widgets/number_pad.dart';
import 'estimate_screen.dart';
import 'sell_draft.dart';

/// S8. Huge weight number with -1, -0.5, +0.5, +1, +5 kg buttons, or type
/// the weight on a big keypad in kilos or grams. Every change is spoken, and
/// the fair price is shown live (also on the Next button).
class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  static const steps = <(int grams, String label)>[
    (-1000, '−1'),
    (-500, '−½'),
    (500, '+½'),
    (1000, '+1'),
    (5000, '+5'),
  ];

  /// Spoken/shown weight: grams below 1 kg ("350 g"), else kilos ("2.5 kg").
  static (String number, String unitKey) display(int grams) =>
      grams < 1000 ? ('$grams', 'grams') : (Fmt.kg(grams), 'kg');

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

enum _Unit { kg, g }

class _WeightScreenState extends ConsumerState<WeightScreen> {
  bool _typing = false;
  _Unit _unit = _Unit.kg;
  String _typed = '';

  void _speakWeight(int grams) {
    final (n, unit) = WeightScreen.display(grams);
    ref.speak(unit == 'grams' ? 'weight_spoken_g' : 'weight_spoken', {
      'weight': n,
    });
  }

  void _change(int delta) {
    ref.read(sellDraftProvider.notifier).changeWeight(delta);
    _speakWeight(ref.read(sellDraftProvider).weightGrams);
  }

  void _startTyping() {
    setState(() {
      _typing = true;
      _typed = '';
    });
    ref.speak('type_weight');
  }

  void _finishTyping() {
    final n = int.tryParse(_typed) ?? 0;
    final grams = _unit == _Unit.kg ? n * 1000 : n;
    ref.read(sellDraftProvider.notifier).setWeight(grams);
    setState(() => _typing = false);
    _speakWeight(ref.read(sellDraftProvider).weightGrams);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final grams = ref.watch(sellDraftProvider.select((d) => d.weightGrams));
    final price = ref.watch(draftPriceProvider);
    final estimate = price == null || grams == 0
        ? null
        : Valuation.estimate(grams, price);
    final (number, unitKey) = _typing
        ? (_typed.isEmpty ? '0' : _typed, _unit == _Unit.kg ? 'kg' : 'grams')
        : WeightScreen.display(grams);

    final weightText = FittedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: _typing ? 88 : 120,
              fontWeight: FontWeight.w900,
              color: _typing ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          const SizedBox(width: 12),
          Text(s.t(unitKey), style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );

    return KScaffold(
      titleKey: 'tile_sell',
      instructionKey: 'weight_instruction',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Kilos / grams: also the unit used when typing.
                Expanded(
                  child: SegmentedButton<_Unit>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _Unit.kg,
                        icon: const Icon(Icons.scale),
                        label: Text(s.t('kg')),
                      ),
                      ButtonSegment(value: _Unit.g, label: Text(s.t('grams'))),
                    ],
                    selected: {_unit},
                    onSelectionChanged: (v) {
                      setState(() => _unit = v.first);
                      ref.speak(v.first == _Unit.kg ? 'kg' : 'grams');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  iconSize: 32,
                  tooltip: s.t('type_weight'),
                  icon: Icon(_typing ? Icons.close : Icons.keyboard),
                  onPressed: _typing
                      ? () => setState(() => _typing = false)
                      : _startTyping,
                ),
              ],
            ),
            Expanded(child: Center(child: weightText)),
            if (_typing)
              NumberPad(
                okLabel: s.t('ok'),
                deleteLabel: s.t('delete'),
                onDigit: (d) {
                  if (_typed.length < (_unit == _Unit.kg ? 4 : 7)) {
                    setState(() => _typed = _typed == '0' ? '$d' : '$_typed$d');
                  }
                },
                onDelete: () {
                  if (_typed.isNotEmpty) {
                    setState(
                      () => _typed = _typed.substring(0, _typed.length - 1),
                    );
                  }
                },
                onOk: _typed.isEmpty ? null : _finishTyping,
              )
            else ...[
              if (estimate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '~₹${Fmt.indian(estimate.spokenRupees)}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.confirmed,
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final (delta, label) in WeightScreen.steps)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SizedBox(
                          height: 72,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: delta < 0
                                  ? AppColors.hazard.withValues(alpha: 0.15)
                                  : AppColors.confirmed.withValues(alpha: 0.18),
                            ),
                            onPressed: delta < 0 && grams == 0
                                ? null
                                : () => _change(delta),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ActionButton(
                icon: Icons.arrow_forward,
                labelKey: 'next',
                extra: estimate == null
                    ? null
                    : '~₹${Fmt.indian(estimate.spokenRupees)}',
                colour: AppColors.confirmed,
                onPressed: grams == 0
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EstimateScreen(),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
