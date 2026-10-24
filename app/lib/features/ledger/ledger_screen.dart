import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import '../handover/handover_screen.dart';
import 'add_sale_screen.dart';
import 'ledger_providers.dart';

/// S13. Today / this week / money still due, then every entry.
/// The speaker reads "Today you got 640 rupees, 200 rupees still due".
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  static int _rs(int paise) => (paise + 50) ~/ 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final sum = ref.watch(ledgerSummaryProvider);
    final entries = ref.watch(ledgerProvider);
    final materials = {
      for (final m
          in ref.watch(materialsProvider).value ?? const <ScrapMaterial>[])
        m.code: m,
    };

    return KScaffold(
      titleKey: 'tile_earnings',
      instructionKey: 'ledger_summary',
      instructionParams: {
        'paid': _rs(sum.todayPaidPaise),
        'due': _rs(sum.todayDuePaise),
        'week': _rs(sum.weekPaidPaise),
      },
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _Total(
                  Icons.payments,
                  'today_got',
                  sum.todayPaidPaise,
                  AppColors.confirmed,
                ),
                _Total(
                  Icons.schedule,
                  'today_due',
                  sum.todayDuePaise,
                  AppColors.pending,
                ),
                _Total(
                  Icons.date_range,
                  'this_week',
                  sum.weekPaidPaise,
                  AppColors.brand,
                ),
              ],
            ),
          ),
          if (sum.totalDuePaise > 0)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.pending.withValues(alpha: 0.15),
              child: ListTile(
                leading: const Icon(
                  Icons.schedule,
                  color: AppColors.pending,
                  size: 36,
                ),
                title: Text(s.t('money_due')),
                trailing: Text(
                  Fmt.rupees(sum.totalDuePaise),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 96,
                          color: Colors.grey,
                        ),
                        Text(s.t('ledger_empty')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      for (final e in entries)
                        _EntryTile(
                          entry: e,
                          material: materials[e.materialCode],
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ActionButton(
              icon: Icons.add,
              labelKey: 'add_sale',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddSaleScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Total extends ConsumerWidget {
  const _Total(this.icon, this.labelKey, this.paise, this.colour);

  final IconData icon;
  final String labelKey;
  final int paise;
  final Color colour;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Expanded(
    child: Card(
      color: colour.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () => ref.speak(labelKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: colour, size: 30),
              FittedBox(
                child: Text(
                  Fmt.rupees(paise),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                ref.watch(appStringsProvider).t(labelKey),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, required this.material});

  final LedgerEntry entry;
  final ScrapMaterial? material;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final due = entry.duePaise > 0;
    final (icon, colour) = switch (entry.paymentMode) {
      PaymentMode.cash => (Icons.payments, AppColors.confirmed),
      PaymentMode.upi => (Icons.qr_code_2, AppColors.confirmed),
      PaymentMode.due => (Icons.schedule, AppColors.pending),
    };
    final local = entry.createdAt.toLocal();
    return Card(
      child: ListTile(
        minTileHeight: 64,
        leading: material == null
            ? const Icon(Icons.recycling, size: 36)
            : AppIcons.material(material!.iconAsset, size: 36),
        title: Text(
          Fmt.rupees(entry.amountPaise),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          '${s.t(entry.type == LedgerType.soldElsewhere ? 'sold_elsewhere' : 'from_recycler')} · '
          '${local.day}/${local.month}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colour, size: 28),
            const SizedBox(width: 4),
            Text(
              due
                  ? '${s.t('pay_due')} ${Fmt.rupees(entry.duePaise)}'
                  : s.t(HandoverScreen.modeKey(entry.paymentMode)),
              style: TextStyle(color: colour, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
