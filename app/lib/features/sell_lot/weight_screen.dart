import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import 'estimate_screen.dart';
import 'sell_draft.dart';

/// S8. Huge weight number with -1, -0.5, +0.5, +1, +5 kg buttons.
/// Every change is spoken.
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  static const steps = <(int grams, String label)>[
    (-1000, '−1'),
    (-500, '−½'),
    (500, '+½'),
    (1000, '+1'),
    (5000, '+5'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final grams = ref.watch(sellDraftProvider.select((d) => d.weightGrams));

    void change(int delta) {
      ref.read(sellDraftProvider.notifier).changeWeight(delta);
      final now = ref.read(sellDraftProvider).weightGrams;
      ref.speak('weight_spoken', {'weight': Fmt.kg(now)});
    }

    return KScaffold(
      titleKey: 'tile_sell',
      instructionKey: 'weight_instruction',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.scale, size: 56),
            Expanded(
              child: Center(
                child: FittedBox(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        Fmt.kg(grams),
                        style: const TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        s.t('kg'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final (delta, label) in steps)
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
                              : () => change(delta),
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
        ),
      ),
    );
  }
}
