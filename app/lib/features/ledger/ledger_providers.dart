import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ledger/ledger_summary.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';

/// The collector's full ledger: saved entries plus confirmed handovers,
/// newest first, no duplicates.
final ledgerProvider = Provider<List<LedgerEntry>>((ref) {
  final handovers = ref.watch(myHandoversProvider).value ?? const <Handover>[];
  return mergeLedger(
    ref.watch(mySavedLedgerProvider).value ?? const [],
    (ref.watch(myConfirmationsProvider).value ?? const {}).values,
    materialByHandover: {for (final h in handovers) h.id: h.materialCode},
  );
});

final ledgerSummaryProvider = Provider<LedgerSummary>(
  (ref) => LedgerSummary.compute(ref.watch(ledgerProvider), DateTime.now()),
);

/// Writes a ledger entry for every confirmation that does not have one yet.
/// Watched by the collector home, so it runs whenever confirmations sync.
/// Entry ids are fixed per handover, so this is safe to repeat.
final ledgerAutoWriterProvider = Provider<void>((ref) {
  final repo = ref.watch(recordsRepositoryProvider);
  final saved = ref.watch(mySavedLedgerProvider);
  final confirmations = ref.watch(myConfirmationsProvider).value ?? const {};
  final handovers = ref.watch(myHandoversProvider).value ?? const <Handover>[];
  if (repo == null || !saved.hasValue) return;
  final have = {for (final e in saved.value!) e.id};
  final material = {for (final h in handovers) h.id: h.materialCode};
  for (final c in confirmations.values) {
    if (!have.contains('h_${c.handoverId}')) {
      repo.saveLedgerEntry(
        entryFromConfirmation(c, materialCode: material[c.handoverId]),
      );
    }
  }
});
