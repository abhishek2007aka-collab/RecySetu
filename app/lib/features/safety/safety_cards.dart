import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/theme/app_theme.dart';

/// One safety rule: a picture (icons, no image files), a short title and a
/// spoken explanation. Ids match `safetyCardIds` in data/materials.csv.
class SafetyCard {
  const SafetyCard(this.id, this.icons, {this.forbidden = true});

  final String id;
  final List<IconData> icons;

  /// Red "NO" sign over the picture (false for "do this" rules).
  final bool forbidden;

  String get titleKey => 'safety_${id}_title';
  String get textKey => 'safety_${id}_text';
}

const safetyCards = <SafetyCard>[
  SafetyCard('no_burning', [Icons.cable, Icons.local_fire_department]),
  SafetyCard('no_break_crt', [Icons.tv, Icons.handyman]),
  SafetyCard('battery_fire_water', [
    Icons.battery_alert,
    Icons.local_fire_department,
    Icons.water_drop,
  ]),
  SafetyCard('gloves_pcb', [Icons.back_hand, Icons.memory], forbidden: false),
  SafetyCard('no_acid', [Icons.science, Icons.memory]),
];

SafetyCard? safetyCardById(String id) =>
    safetyCards.where((c) => c.id == id).firstOrNull;

/// The card's picture: its icons side by side, with a red ⃠ over them for
/// "never do this" rules and a green ✓ for "always do this".
class SafetyPicture extends StatelessWidget {
  const SafetyPicture({super.key, required this.card, this.size = 64});

  final SafetyCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colour = card.forbidden ? AppColors.hazard : AppColors.confirmed;
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final icon in card.icons)
              Icon(icon, size: size, color: Colors.grey.shade800),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Icon(
            card.forbidden ? Icons.block : Icons.check_circle,
            size: size * 0.7,
            color: colour,
          ),
        ),
      ],
    );
  }
}

/// A full card for lists and the auto-shown warning.
class SafetyCardView extends ConsumerWidget {
  const SafetyCardView({super.key, required this.card, this.onTap});

  final SafetyCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final colour = card.forbidden ? AppColors.hazard : AppColors.confirmed;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colour, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SafetyPicture(card: card),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    card.forbidden ? Icons.warning : Icons.check_circle,
                    color: colour,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.t(card.titleKey),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colour,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                s.t(card.textKey),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
