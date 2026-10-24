import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import 'safety_cards.dart';

/// S14. All safety cards; tap one to hear it.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KScaffold(
      titleKey: 'tile_safety',
      instructionKey: 'safety_instruction',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final card in safetyCards)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SafetyCardView(
                card: card,
                onTap: () => ref.speak(card.textKey, const {}, true),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown automatically the first time a collector picks a dangerous
/// material (PLAN.md Phase 9): its first safety card, spoken out loud.
class SafetyFirstScreen extends ConsumerWidget {
  const SafetyFirstScreen({
    super.key,
    required this.card,
    required this.onDone,
  });

  final SafetyCard card;
  final VoidCallback onDone;

  static String seenKey(String materialCode) => 'safety_seen_$materialCode';

  /// True if this dangerous material's safety card should be shown now.
  static bool shouldShow(WidgetRef ref, ScrapMaterial m) =>
      m.hazard == Hazard.high &&
      m.safetyCardIds.any((id) => safetyCardById(id) != null) &&
      !(ref.read(sharedPrefsProvider).getBool(seenKey(m.code)) ?? false);

  static SafetyCard firstCard(ScrapMaterial m) =>
      m.safetyCardIds.map(safetyCardById).whereType<SafetyCard>().first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KScaffold(
      titleKey: 'safety_first',
      instructionKey: card.textKey,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.health_and_safety,
              size: 64,
              color: AppColors.hazard,
            ),
            const SizedBox(height: 8),
            SafetyCardView(
              card: card,
              onTap: () => ref.speak(card.textKey, const {}, true),
            ),
            const Spacer(),
            ActionButton(
              icon: Icons.check,
              labelKey: 'understood',
              colour: AppColors.confirmed,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
