import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import 'sell_draft.dart';
import 'weight_screen.dart';

/// S7. Picture tiles, 2 columns. Dangerous materials carry a red warning
/// badge and say a warning when chosen.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(materialsProvider).value ?? const <ScrapMaterial>[];
    // Start loading prices now so the price screen (S9) has them at once.
    ref.watch(pricesProvider);
    final suggested = ref.watch(suggestedMaterialProvider);
    // The suggested material goes first; the collector can still pick any.
    final materials = [
      ?suggested,
      for (final m in all)
        if (m != suggested) m,
    ];
    final s = ref.watch(appStringsProvider);
    // If the suggestion arrives after the screen opened, say it then.
    ref.listen(suggestedMaterialProvider, (before, now) {
      if (before == null && now != null) {
        ref.speak('ai_suggestion', {'material': s.t(now.nameKey)});
      }
    });
    return KScaffold(
      titleKey: 'tile_sell',
      instructionKey: suggested == null
          ? 'category_instruction'
          : 'ai_suggestion',
      instructionParams: {
        'material': suggested == null ? '' : s.t(suggested.nameKey),
      },
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final m in materials)
            _MaterialTile(
              material: m,
              suggested: m == suggested,
              onTap: () {
                ref.read(sellDraftProvider.notifier).chooseMaterial(m.code);
                if (m.hazard == Hazard.high) ref.speak('hazard_warning');
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const WeightScreen()),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MaterialTile extends ConsumerWidget {
  const _MaterialTile({
    required this.material,
    required this.onTap,
    this.suggested = false,
  });

  final ScrapMaterial material;
  final VoidCallback onTap;

  /// Highlighted because the recogniser thinks the photo shows this.
  final bool suggested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final high = material.hazard == Hazard.high;
    final colour = high
        ? AppColors.hazard
        : Theme.of(context).colorScheme.primary;
    return Material(
      color: colour.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: suggested ? AppColors.confirmed : colour,
          width: suggested ? 5 : (high ? 3 : 1.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ref.speak(material.nameKey);
          onTap();
        },
        onLongPress: () => ref.speak(material.nameKey),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcons.material(
                    material.iconAsset,
                    size: 64,
                    color: colour,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.t(material.nameKey),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            if (suggested)
              Positioned(
                top: 6,
                left: 6,
                child: Chip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(s.t('suggested')),
                  backgroundColor: AppColors.confirmed.withValues(alpha: 0.2),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            if (high)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.warning, color: AppColors.hazard, size: 36),
              ),
          ],
        ),
      ),
    );
  }
}
