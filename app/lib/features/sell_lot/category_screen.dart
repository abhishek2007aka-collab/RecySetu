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
    final materials = ref.watch(materialsProvider).value ?? const [];
    // Start loading prices now so the price screen (S9) has them at once.
    ref.watch(pricesProvider);
    return KScaffold(
      titleKey: 'tile_sell',
      instructionKey: 'category_instruction',
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final m in materials)
            _MaterialTile(
              material: m,
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
  const _MaterialTile({required this.material, required this.onTap});

  final ScrapMaterial material;
  final VoidCallback onTap;

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
        side: BorderSide(color: colour, width: high ? 3 : 1.5),
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
