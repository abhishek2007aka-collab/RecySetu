import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../audio/audio_service.dart';
import '../theme/app_theme.dart';

/// Top-bar switch: voice on (🔊) / off (🔇). Off stops any speech at once;
/// on says "Voice on" so the user knows it worked.
class VoiceToggleButton extends ConsumerWidget {
  const VoiceToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(voiceOnProvider);
    final s = ref.watch(appStringsProvider);
    return IconButton(
      icon: Icon(
        on ? Icons.record_voice_over : Icons.voice_over_off,
        color: on ? null : AppColors.hazard,
      ),
      tooltip: s.t(on ? 'voice_off' : 'voice_on'),
      onPressed: () {
        ref.read(voiceOnProvider.notifier).set(!on);
        if (on) {
          ref.stopSpeaking();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.voice_over_off, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      s.t('voice_off'),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            );
        } else {
          ref.speak('voice_on');
        }
      },
    );
  }
}
