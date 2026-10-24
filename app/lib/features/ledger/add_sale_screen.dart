import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../core/widgets/number_pad.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';

/// "Sold elsewhere": keeps the ledger honest when scrap goes to a local
/// dealer. Pick the material, type the rupees, tap Cash or UPI.
class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({super.key});

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  String? _material;
  String _rupees = '';

  void _save(PaymentMode mode) {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(recordsRepositoryProvider);
    final amount = int.tryParse(_rupees) ?? 0;
    if (uid == null || repo == null || amount == 0) return;
    repo.saveLedgerEntry(
      LedgerEntry(
        id: const Uuid().v4(),
        collectorUid: uid,
        type: LedgerType.soldElsewhere,
        amountPaise: amount * 100,
        paidPaise: amount * 100,
        paymentMode: mode,
        createdAt: DateTime.now().toUtc(),
        materialCode: _material,
      ),
    );
    ref.speak('saved');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final materials =
        ref.watch(materialsProvider).value ?? const <ScrapMaterial>[];

    if (_material == null) {
      return KScaffold(
        titleKey: 'add_sale',
        instructionKey: 'add_sale_instruction',
        body: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(8),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final m in materials)
              Card(
                child: InkWell(
                  onTap: () {
                    ref.speak(m.nameKey);
                    setState(() => _material = m.code);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcons.material(m.iconAsset, size: 44),
                      Text(
                        s.t(m.nameKey),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final amount = int.tryParse(_rupees) ?? 0;
    return KScaffold(
      key: const ValueKey('amount'),
      titleKey: 'add_sale',
      instructionKey: 'amount_instruction',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  child: Text(
                    '₹${Fmt.indian(amount)}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            NumberPad(
              okLabel: s.t('ok'),
              deleteLabel: s.t('delete'),
              onDigit: (d) {
                if (_rupees.length < 7) setState(() => _rupees = '$_rupees$d');
              },
              onDelete: () {
                if (_rupees.isNotEmpty) {
                  setState(
                    () => _rupees = _rupees.substring(0, _rupees.length - 1),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            // Cash first: it is the most common way collectors are paid.
            Row(
              children: [
                for (final (mode, icon, key) in const [
                  (PaymentMode.cash, Icons.payments, 'pay_cash'),
                  (PaymentMode.upi, Icons.qr_code_2, 'pay_upi'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SizedBox(
                        height: 68,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.confirmed,
                          ),
                          icon: Icon(icon, size: 30),
                          label: Text(s.t(key)),
                          onPressed: amount == 0 ? null : () => _save(mode),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
