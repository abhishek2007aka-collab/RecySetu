import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/i18n/languages.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../debug/audio_debug_screen.dart';

/// Phase 0-2 placeholder: Firebase status, language switch, and materials
/// with spoken prices. Phase 3 replaces it with the real 4-tile home (S5).
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final all = ref.watch(allStringsProvider);
    final lang = ref.watch(languageProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final materials = ref.watch(materialsProvider).value ?? const [];
    final prices = {
      for (final p in ref.watch(pricesProvider).value ?? const [])
        p.materialCode: p,
    };

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AudioDebugScreen()),
          ),
          child: Text(s.t('app_name')),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FirebaseStatus(
            ready: firebaseReady,
            label: s.t(firebaseReady ? 'firebase_ready' : 'firebase_not_ready'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in appLanguages)
                ChoiceChip(
                  label: Text(all[l.code]!.t('lang_name')),
                  selected: l.code == lang,
                  onSelected: (_) =>
                      ref.read(languageProvider.notifier).select(l.code),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final m in materials)
            if (prices[m.code] case final p?)
              ListTile(
                minTileHeight: AppTheme.minTouch,
                leading: AppIcons.material(m.iconAsset, size: 40),
                title: Text(s.t(m.nameKey)),
                subtitle: Text(
                  '₹${p.lowPaisePerKg ~/ 100}–${p.highPaisePerKg ~/ 100} '
                  '${s.t('per_kg')}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: const Icon(Icons.volume_up, size: 32),
                onTap: () => ref.speak('price_per_kg', {
                  'material': s.t(m.nameKey),
                  'low': p.lowPaisePerKg ~/ 100,
                  'high': p.highPaisePerKg ~/ 100,
                }),
              ),
        ],
      ),
    );
  }
}

class _FirebaseStatus extends StatelessWidget {
  const _FirebaseStatus({required this.ready, required this.label});

  final bool ready;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colour = ready ? AppColors.confirmed : AppColors.pending;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ready ? Icons.check_circle : Icons.schedule,
          color: colour,
          size: 36,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: colour),
        ),
      ],
    );
  }
}
