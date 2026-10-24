import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/ledger/deal_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import '../handover/handover_screen.dart';
import '../onboarding/session.dart';

final _recentProvider = StreamProvider<List<Confirmation>>((ref) {
  final repo = ref.watch(recordsRepositoryProvider);
  final id = ref.watch(sessionProvider).recyclerId;
  if (repo == null || id == null) return Stream.value(const []);
  return repo
      .watchRecyclerConfirmations(id)
      .map(
        (list) => list..sort((a, b) => b.confirmedAt.compareTo(a.confirmedAt)),
      );
});

/// The collectors' "money received?" answers for this recycler's deals.
final recyclerReceiptsProvider = StreamProvider<Map<String, Receipt>>((ref) {
  final repo = ref.watch(recordsRepositoryProvider);
  final id = ref.watch(sessionProvider).recyclerId;
  if (repo == null || id == null) return Stream.value(const {});
  return repo
      .watchRecyclerReceipts(id)
      .map((list) => {for (final r in list) r.handoverId: r});
});

/// Icon, colour and words for a deal as the recycler sees it.
(IconData, Color, String) recyclerDealLook(Confirmation c, Receipt? r) =>
    switch (dealStage(c, r)) {
      DealStage.complete => (
        Icons.check_circle,
        AppColors.confirmed,
        'status_complete',
      ),
      DealStage.notReceived => (
        Icons.warning,
        AppColors.hazard,
        'status_not_received',
      ),
      DealStage.disputed => (
        Icons.warning,
        AppColors.hazard,
        'status_disputed',
      ),
      _ => (Icons.schedule, AppColors.pending, 'status_wait_collector'),
    };

/// Recycler's confirmed deals, newest first.
class RecentDealsScreen extends ConsumerWidget {
  const RecentDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final deals = ref.watch(_recentProvider).value ?? const <Confirmation>[];
    final receipts = ref.watch(recyclerReceiptsProvider).value ?? const {};
    return KScaffold(
      titleKey: 'tile_recent',
      instructionKey: 'recent_instruction',
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          for (final c in deals)
            Builder(
              builder: (context) {
                final (icon, colour, key) = recyclerDealLook(
                  c,
                  receipts[c.handoverId],
                );
                return Card(
                  child: ListTile(
                    minTileHeight: 64,
                    leading: Icon(icon, color: colour, size: 36),
                    title: Text(
                      '${Fmt.rupees(c.amountPaise)} · ${s.t(HandoverScreen.modeKey(c.paymentMode))}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(
                      '${s.t(key)}\n'
                      '${Fmt.kg(c.measuredWeightGrams)} ${s.t('kg')} · '
                      '${c.confirmedAt.toLocal().toString().substring(0, 16)}',
                    ),
                    onTap: () => ref.speak(key, const {}, true),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
