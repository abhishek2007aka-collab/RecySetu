import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../audio/audio_service.dart';
import '../theme/app_theme.dart';

enum SyncState { synced, pending, offline }

/// Pure rule, unit-tested: offline wins, then pending writes, else synced.
SyncState syncStateFor({required bool online, required bool pendingWrites}) {
  if (!online) return SyncState.offline;
  return pendingWrites ? SyncState.pending : SyncState.synced;
}

final onlineProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  bool isOnline(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);
  yield isOnline(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(isOnline);
});

final syncStateProvider = Provider<SyncState>((ref) {
  final online = ref.watch(onlineProvider).value ?? true;
  final pending = ref.watch(pendingWritesProvider).value ?? false;
  return syncStateFor(online: online, pendingWrites: pending);
});

/// Small icon for the top bar. Never blocks; tap to hear what it means.
class SyncIcon extends ConsumerWidget {
  const SyncIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, colour, key) = switch (ref.watch(syncStateProvider)) {
      SyncState.synced => (Icons.cloud_done, AppColors.confirmed, 'sync_done'),
      SyncState.pending => (
        Icons.cloud_upload,
        AppColors.pending,
        'sync_pending',
      ),
      SyncState.offline => (
        Icons.cloud_off,
        Colors.grey.shade700,
        'sync_offline',
      ),
    };
    return IconButton(
      icon: Icon(icon, color: colour),
      onPressed: () => ref.speak(key),
    );
  }
}
