import '../../data/models/records.dart';

/// Totals for the earnings screen (S13). Money in paise.
/// "Today" and "this week" use the phone's local time; weeks start Monday.
class LedgerSummary {
  const LedgerSummary({
    required this.todayPaidPaise,
    required this.todayDuePaise,
    required this.weekPaidPaise,
    required this.totalDuePaise,
  });

  final int todayPaidPaise;
  final int todayDuePaise;
  final int weekPaidPaise;

  /// Everything still owed, any date.
  final int totalDuePaise;

  static DateTime _wallClock(DateTime utc) => utc.toLocal();

  /// [nowLocal] is the phone's local time. [toLocal] turns stored UTC times
  /// into local wall-clock times (tests pass a fixed offset).
  static LedgerSummary compute(
    Iterable<LedgerEntry> entries,
    DateTime nowLocal, {
    DateTime Function(DateTime utc) toLocal = _wallClock,
  }) {
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final weekStart = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day - (nowLocal.weekday - DateTime.monday),
    );
    var todayPaid = 0, todayDue = 0, weekPaid = 0, totalDue = 0;
    for (final e in entries) {
      final at = toLocal(e.createdAt);
      final due = e.duePaise > 0 ? e.duePaise : 0;
      totalDue += due;
      if (!at.isBefore(weekStart)) weekPaid += e.paidPaise;
      if (!at.isBefore(today)) {
        todayPaid += e.paidPaise;
        todayDue += due;
      }
    }
    return LedgerSummary(
      todayPaidPaise: todayPaid,
      todayDuePaise: todayDue,
      weekPaidPaise: weekPaid,
      totalDuePaise: totalDue,
    );
  }
}

/// A ledger entry made from a recycler's confirmation. Its id is fixed per
/// handover, so writing it again never makes a duplicate.
LedgerEntry entryFromConfirmation(Confirmation c, {String? materialCode}) =>
    LedgerEntry(
      id: 'h_${c.handoverId}',
      collectorUid: c.collectorUid,
      type: LedgerType.handover,
      amountPaise: c.amountPaise,
      paidPaise: c.paidPaise,
      paymentMode: c.paymentMode,
      createdAt: c.confirmedAt,
      handoverId: c.handoverId,
      materialCode: materialCode,
    );

/// Ledger shown to the collector: saved entries plus any confirmation not
/// yet written as an entry, newest first, with no duplicates.
List<LedgerEntry> mergeLedger(
  Iterable<LedgerEntry> saved,
  Iterable<Confirmation> confirmations, {
  Map<String, String> materialByHandover = const {},
}) {
  final byId = <String, LedgerEntry>{
    for (final c in confirmations)
      'h_${c.handoverId}': entryFromConfirmation(
        c,
        materialCode: materialByHandover[c.handoverId],
      ),
  };
  for (final e in saved) {
    byId[e.id] = e;
  }
  return byId.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
