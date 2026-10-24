import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/format.dart';
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

/// Recycler's confirmed deals, newest first.
class RecentDealsScreen extends ConsumerWidget {
  const RecentDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final deals = ref.watch(_recentProvider).value ?? const <Confirmation>[];
    return KScaffold(
      titleKey: 'tile_recent',
      instructionKey: 'recent_instruction',
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          for (final c in deals)
            Card(
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(
                  c.flags.isEmpty ? Icons.check_circle : Icons.warning,
                  color: c.flags.isEmpty
                      ? AppColors.confirmed
                      : AppColors.hazard,
                  size: 36,
                ),
                title: Text(
                  '${Fmt.rupees(c.amountPaise)} · ${s.t(HandoverScreen.modeKey(c.paymentMode))}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  '${Fmt.kg(c.measuredWeightGrams)} ${s.t('kg')} · '
                  '${c.confirmedAt.toLocal().toString().substring(0, 16)}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
