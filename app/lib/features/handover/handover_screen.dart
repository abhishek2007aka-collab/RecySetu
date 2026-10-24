import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/hash/handover_hasher.dart';
import '../../core/ledger/deal_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import 'payment_question.dart';

/// S11. Shows the sealed handover as a QR code plus a short reference that
/// is spoken character by character. When the recycler's confirmation
/// syncs, the collector is asked "did you get the money?"; the status turns
/// green only after they say yes.
class HandoverScreen extends ConsumerWidget {
  const HandoverScreen({
    super.key,
    required this.handover,
    required this.recyclerName,
  });

  final Handover handover;
  final String recyclerName;

  /// "A3F9-1C2B" -> "A 3 F 9, 1 C 2 B" so TTS reads each character.
  static String spokenRef(String ref) =>
      ref.split('-').map((part) => part.split('').join(' ')).join(', ');

  static String modeKey(PaymentMode m) => switch (m) {
    PaymentMode.cash => 'pay_cash',
    PaymentMode.upi => 'pay_upi',
    PaymentMode.due => 'pay_due',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final shortRef = HandoverHasher.shortRef(handover.hash);
    final confirmation = ref.watch(myConfirmationsProvider).value?[handover.id];

    final receipt = ref.watch(myReceiptsProvider).value?[handover.id];
    final stage = dealStage(confirmation, receipt);

    final (icon, colour, statusKey) = switch (stage) {
      DealStage.disputed => (
        Icons.warning,
        AppColors.hazard,
        'status_disputed',
      ),
      DealStage.complete => (
        Icons.check_circle,
        AppColors.confirmed,
        'status_complete',
      ),
      _ => (Icons.schedule, AppColors.pending, 'status_pending'),
    };

    return KScaffold(
      titleKey: 'handover_title',
      instructionKey: 'handover_instruction',
      instructionParams: {'ref': spokenRef(shortRef)},
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: QrImageView(
              data: HandoverHasher.qrPayload(handover),
              size: 260,
              backgroundColor: Colors.white,
            ),
          ),
          Center(
            child: Text(
              shortRef,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (stage == DealStage.waitingCollector ||
              stage == DealStage.notReceived)
            PaymentQuestionCard(
              confirmation: confirmation!,
              saidNo: stage == DealStage.notReceived,
            )
          else
            Card(
              color: colour.withValues(alpha: 0.12),
              child: ListTile(
                minTileHeight: 72,
                leading: Icon(icon, color: colour, size: 44),
                title: Text(
                  s.t(statusKey),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: colour),
                ),
                subtitle: confirmation == null
                    ? null
                    : Text(
                        '${Fmt.rupees(confirmation.paidPaise)} · '
                        '${s.t(modeKey(confirmation.paymentMode))}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                onTap: () => ref.speak(statusKey, const {}, true),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.factory, size: 32),
            title: Text(recyclerName),
            trailing: Text(
              '${s.t('agreed')}: ${Fmt.rupees(handover.agreedPaise)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.t('proof_note'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          ActionButton(
            icon: Icons.home,
            labelKey: 'done',
            colour: AppColors.confirmed,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
