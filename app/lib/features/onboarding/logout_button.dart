import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../sell_lot/sell_draft.dart';
import 'session.dart';

/// Top-bar logout. Asks first (big Yes / No, spoken). Refuses while some
/// records have not reached the server yet, because after logging out they
/// could no longer be sent and would be lost.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    final unsent = ref.read(pendingWritesProvider).value ?? false;
    final key = unsent ? 'logout_wait_sync' : 'logout_confirm';
    ref.speak(key);

    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          unsent ? Icons.cloud_upload : Icons.logout,
          size: 48,
          color: unsent ? AppColors.pending : null,
        ),
        content: Text(s.t(key), style: Theme.of(context).textTheme.titleLarge),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          if (!unsent)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.hazard),
              icon: const Icon(Icons.check, size: 28),
              label: Text(s.t('yes')),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          OutlinedButton.icon(
            icon: Icon(unsent ? Icons.check : Icons.close, size: 28),
            label: Text(s.t(unsent ? 'ok' : 'no')),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (yes != true) return;

    await ref.read(audioServiceProvider).stop();
    ref.read(sellDraftProvider.notifier).start();
    await ref.read(sessionProvider.notifier).reset();
    await ref.read(firebaseAuthProvider)?.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.logout),
    tooltip: ref.watch(appStringsProvider).t('logout'),
    onPressed: () => _logout(context, ref),
  );
}
