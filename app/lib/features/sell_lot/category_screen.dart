import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import '../safety/safety_screen.dart';
import 'sell_draft.dart';
import 'weight_screen.dart';

/// S7. Picture tiles, 2 columns. When the AI is sure, its pick is shown big
/// on top and the other materials below. Dangerous materials carry a red
/// warning badge and say a warning when chosen.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(materialsProvider).value ?? const <ScrapMaterial>[];
    // Start loading prices now so the price screen (S9) has them at once.
    ref.watch(pricesProvider);
    final suggested = ref.watch(suggestedMaterialProvider);
    final percent =
        ((ref.watch(draftSuggestionProvider)?.confidence ?? 0) * 100).round();
    // Everything except the suggestion; the collector can still pick any.
    final others = [
      for (final m in all)
        if (m != suggested) m,
    ];
    final s = ref.watch(appStringsProvider);

    void choose(ScrapMaterial m) {
      ref.read(sellDraftProvider.notifier).chooseMaterial(m.code);
      final nav = Navigator.of(context);
      if (SafetyFirstScreen.shouldShow(ref, m)) {
        // First time with this dangerous item: safety card first.
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => SafetyFirstScreen(
              card: SafetyFirstScreen.firstCard(m),
              onDone: () {
                ref
                    .read(sharedPrefsProvider)
                    .setBool(SafetyFirstScreen.seenKey(m.code), true);
                nav.pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const WeightScreen()),
                );
              },
            ),
          ),
        );
        return;
      }
      if (m.hazard == Hazard.high) ref.speak('hazard_warning');
      nav.push(MaterialPageRoute<void>(builder: (_) => const WeightScreen()));
    }

    // If the suggestion arrives after the screen opened, say it then.
    ref.listen(suggestedMaterialProvider, (before, now) {
      if (before == null && now != null) {
        final p = ((ref.read(draftSuggestionProvider)?.confidence ?? 0) * 100)
            .round();
        ref.speak('ai_suggestion', {
          'material': s.t(now.nameKey),
          'percent': p,
        });
      }
    });
    return KScaffold(
      titleKey: 'tile_sell',
      instructionKey: suggested == null
          ? 'category_instruction'
          : 'ai_suggestion',
      instructionParams: {
        'material': suggested == null ? '' : s.t(suggested.nameKey),
        'percent': percent,
      },
      body: CustomScrollView(
        slivers: [
          // The AI's pick pops out on top, full width; the rest below.
          if (suggested != null) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 190,
                  child: _MaterialTile(
                    material: suggested,
                    suggestedPercent: percent,
                    onTap: () => choose(suggested),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.grid_view, size: 32),
                title: Text(
                  s.t('pick_other'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.volume_up),
                onTap: () => ref.speak('pick_other', const {}, true),
              ),
            ),
          ],
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, suggested == null ? 12 : 0, 12, 12),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final m in others)
                  _MaterialTile(material: m, onTap: () => choose(m)),
              ],
            ),
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
    this.suggestedPercent,
  });

  final ScrapMaterial material;
  final VoidCallback onTap;

  /// Set (0-100) when the recogniser thinks the photo shows this material.
  final int? suggestedPercent;

  bool get suggested => suggestedPercent != null;

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
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 3,
                      child: FittedBox(
                        child: AppIcons.material(
                          material.iconAsset,
                          size: 64,
                          color: colour,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          s.t(material.nameKey),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (suggested)
              Positioned(
                top: 6,
                left: 6,
                child: Chip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('${s.t('suggested')} $suggestedPercent%'),
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
