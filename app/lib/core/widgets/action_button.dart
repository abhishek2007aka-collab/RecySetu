import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../audio/audio_service.dart';

/// Full-width main action at the bottom of a screen: icon + 1-2 words.
/// Says its label when tapped.
class ActionButton extends ConsumerWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.labelKey,
    required this.onPressed,
    this.colour,
    this.speakLabel = true,
    this.extra,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback? onPressed;
  final Color? colour;
  final bool speakLabel;

  /// Shown after the label, e.g. the live price "~₹300".
  final String? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final onPressed = this.onPressed;
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: colour),
        icon: Icon(icon, size: 32),
        label: Text(
          extra == null ? s.t(labelKey) : '${s.t(labelKey)} · $extra',
        ),
        onPressed: onPressed == null
            ? null
            : () {
                if (speakLabel) ref.speak(labelKey);
                onPressed();
              },
      ),
    );
  }
}
