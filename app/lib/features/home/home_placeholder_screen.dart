import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';

/// Phase 0 placeholder. Phase 3 replaces it with the real 4-tile home (S5).
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('app_name'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.recycling,
                size: 120,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                s.t('home_placeholder'),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              _FirebaseStatus(
                ready: firebaseReady,
                label: s.t(
                  firebaseReady ? 'firebase_ready' : 'firebase_not_ready',
                ),
              ),
            ],
          ),
        ),
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
