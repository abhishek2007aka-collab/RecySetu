import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';

/// Phase 0/1 placeholder: Firebase status + materials with prices.
/// Phase 3 replaces it with the real 4-tile home (S5).
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final materials = ref.watch(materialsProvider).value ?? const [];
    final prices = {
      for (final p in ref.watch(pricesProvider).value ?? const [])
        p.materialCode: p,
    };

    return Scaffold(
      appBar: AppBar(title: Text(s.t('app_name'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FirebaseStatus(
            ready: firebaseReady,
            label: s.t(firebaseReady ? 'firebase_ready' : 'firebase_not_ready'),
          ),
          const SizedBox(height: 16),
          for (final m in materials)
            ListTile(
              minTileHeight: AppTheme.minTouch,
              leading: AppIcons.material(m.iconAsset, size: 40),
              title: Text(s.t(m.nameKey)),
              trailing: prices[m.code] == null
                  ? null
                  : Text(
                      '₹${prices[m.code]!.lowPaisePerKg ~/ 100}–'
                      '${prices[m.code]!.highPaisePerKg ~/ 100} ${s.t('per_kg')}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
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
