import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/valuation/trend.dart';
import '../../data/models/catalog.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/providers.dart';

/// S12. Every material with its ₹/kg range and a trend arrow.
/// Tap a tile to hear "PCB: 180 to 220 rupees per kilo. Rate went up".
class RatesBoardScreen extends ConsumerWidget {
  const RatesBoardScreen({super.key});

  static (IconData, Color, String) trendLook(Trend t) => switch (t) {
    Trend.up => (Icons.arrow_upward, AppColors.confirmed, 'trend_up'),
    Trend.down => (Icons.arrow_downward, AppColors.hazard, 'trend_down'),
    Trend.flat => (Icons.arrow_forward, Colors.grey.shade700, 'trend_flat'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final materials = ref.watch(materialsProvider).value ?? const [];
    final prices = {
      for (final p in ref.watch(pricesProvider).value ?? const <Price>[])
        p.materialCode: p,
    };

    return KScaffold(
      titleKey: 'tile_rates',
      instructionKey: 'rates_instruction',
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: [
          for (final m in materials)
            if (prices[m.code] case final p?)
              () {
                final (icon, colour, trendKey) = trendLook(trendFor(p));
                final low = (p.lowPaisePerKg + 50) ~/ 100;
                final high = (p.highPaisePerKg + 50) ~/ 100;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => ref.speak('rate_with_trend', {
                      'material': s.t(m.nameKey),
                      'low': low,
                      'high': high,
                      'trend': s.t(trendKey),
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcons.material(m.iconAsset, size: 44),
                              Icon(icon, color: colour, size: 36),
                            ],
                          ),
                          Text(
                            s.t(m.nameKey),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          FittedBox(
                            child: Text(
                              '₹${Fmt.indian(low)}–${Fmt.indian(high)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(s.t('per_kg')),
                        ],
                      ),
                    ),
                  ),
                );
              }(),
        ],
      ),
    );
  }
}
