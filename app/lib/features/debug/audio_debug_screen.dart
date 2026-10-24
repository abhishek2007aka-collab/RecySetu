import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_theme.dart';

/// Hidden screen (long-press the app title) listing every string key with a
/// play button, so the team can check text and audio in each language.
class AudioDebugScreen extends ConsumerWidget {
  const AudioDebugScreen({super.key});

  /// Sample values for `{slots}` so templates can be heard filled in.
  static const sampleParams = <String, Object>{
    'amount': 340,
    'material': 'PCB',
    'low': 180,
    'high': 220,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('debug_audio_title'))),
      body: ListView(
        children: [
          for (final key in s.keys)
            ListTile(
              minTileHeight: AppTheme.minTouch,
              title: Text(s.t(key, sampleParams)),
              subtitle: Text(key),
              trailing: IconButton(
                icon: const Icon(Icons.volume_up),
                tooltip: s.t('tap_to_hear'),
                onPressed: () => ref.speak(key, sampleParams, true),
              ),
            ),
        ],
      ),
    );
  }
}
