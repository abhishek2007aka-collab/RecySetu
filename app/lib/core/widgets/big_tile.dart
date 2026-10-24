import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../audio/audio_service.dart';

/// A big picture button: icon + 1-2 words. Tap does the action and says the
/// label; long-press only says the label (for "what is this?").
class BigTile extends ConsumerWidget {
  const BigTile({
    super.key,
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.colour,
    this.badge,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;
  final Color? colour;

  /// Small extra icon in the corner, e.g. a hazard warning.
  final Widget? badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final c = colour ?? scheme.primary;
    return Material(
      color: c.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: c, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          ref.speak(labelKey);
          onTap();
        },
        onLongPress: () => ref.speak(labelKey, const {}, true),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(child: Icon(icon, size: 72, color: c)),
                    ),
                    const SizedBox(height: 8),
                    // Shrinks rather than overflowing at very large font sizes.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          s.t(labelKey),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (badge != null) Positioned(top: 8, right: 8, child: badge!),
          ],
        ),
      ),
    );
  }
}
