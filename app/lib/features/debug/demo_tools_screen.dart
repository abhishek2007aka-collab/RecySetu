import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/geo/location.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import 'audio_debug_screen.dart';

/// Hidden demo helpers (long-press the logo on the home screen). Only resets
/// things on this phone; never deletes records.
class DemoToolsScreen extends ConsumerWidget {
  const DemoToolsScreen({super.key});

  /// Forget which safety cards were shown, so they play again.
  static int resetSafetyCards(WidgetRef ref) {
    final prefs = ref.read(sharedPrefsProvider);
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('safety_seen_'))
        .toList();
    for (final k in keys) {
      prefs.remove(k);
    }
    return keys.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final areas = ref.watch(areasProvider).value ?? const <Area>[];

    void done() {
      ref.speak('saved', const {}, true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(s.t('saved')),
              ],
            ),
          ),
        );
    }

    Widget tool(IconData icon, String labelKey, VoidCallback onTap) => Card(
      child: ListTile(
        minTileHeight: 72,
        leading: Icon(icon, size: 36, color: AppColors.brand),
        title: Text(
          s.t(labelKey),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        onTap: onTap,
      ),
    );

    return KScaffold(
      titleKey: 'demo_tools',
      instructionKey: 'demo_tools',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          tool(Icons.health_and_safety, 'demo_reset_safety', () {
            resetSafetyCards(ref);
            done();
          }),
          for (final a in areas.take(1))
            tool(Icons.place, 'demo_set_location', () {
              ref.read(myLocationProvider.notifier).set((
                lat: a.lat,
                lng: a.lng,
              ));
              done();
            }),
          tool(
            Icons.record_voice_over,
            'debug_audio_title',
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AudioDebugScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
