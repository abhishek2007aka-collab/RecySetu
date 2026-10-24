import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ledger/deal_status.dart';
import '../../core/ledger/ledger_summary.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';

/// The collector's full ledger: saved entries plus deals they said "money
/// received" for, newest first, no duplicates.
final ledgerProvider = Provider<List<LedgerEntry>>((ref) {
  final handovers = ref.watch(myHandoversProvider).value ?? const <Handover>[];
  final receipts = ref.watch(myReceiptsProvider).value ?? const {};
  return mergeLedger(
    ref.watch(mySavedLedgerProvider).value ?? const [],
    (ref.watch(myConfirmationsProvider).value ?? const {}).values,
    received: {
      for (final r in receipts.values)
        if (r.received) r.handoverId,
    },
    materialByHandover: {for (final h in handovers) h.id: h.materialCode},
  );
});

final ledgerSummaryProvider = Provider<LedgerSummary>(
  (ref) => LedgerSummary.compute(ref.watch(ledgerProvider), DateTime.now()),
);

/// Recycler-confirmed deals waiting for the collector's "money received?"
/// answer, oldest first.
final paymentsToAnswerProvider = Provider<List<Confirmation>>(
  (ref) => awaitingAnswer(
    (ref.watch(myConfirmationsProvider).value ?? const {}).values,
    ref.watch(myReceiptsProvider).value ?? const {},
  ),
);

/// Saves the collector's answer. "Yes" completes the deal and adds it to
/// the earnings (entry id fixed per handover, so repeating is harmless).
void answerPayment(WidgetRef ref, Confirmation c, {required bool received}) {
  final repo = ref.read(recordsRepositoryProvider);
  if (repo == null) return;
  repo.saveReceipt(receiptFor(c, received: received));
  if (received) {
    final material = (ref.read(myHandoversProvider).value ?? const <Handover>[])
        .where((h) => h.id == c.handoverId)
        .firstOrNull
        ?.materialCode;
    repo.saveLedgerEntry(entryFromConfirmation(c, materialCode: material));
  }
}
