import '../../data/models/records.dart';

/// Where a handover stands. A deal is complete only after the recycler has
/// confirmed AND the collector has said "yes, I got the money".
enum DealStage {
  waitingRecycler,
  waitingCollector,
  notReceived,
  complete,
  disputed,
}

DealStage dealStage(Confirmation? c, Receipt? r) {
  if (c == null) return DealStage.waitingRecycler;
  if (c.disputed) return DealStage.disputed;
  if (r == null) return DealStage.waitingCollector;
  return r.received ? DealStage.complete : DealStage.notReceived;
}

/// The collector's answer to "did you get the money?" for [c].
Receipt receiptFor(Confirmation c, {required bool received, DateTime? at}) =>
    Receipt(
      handoverId: c.handoverId,
      collectorUid: c.collectorUid,
      recyclerId: c.recyclerId,
      received: received,
      amountPaise: c.paidPaise,
      answeredAt: (at ?? DateTime.now()).toUtc(),
    );

/// Confirmed deals still waiting for the collector's "yes", oldest first.
List<Confirmation> awaitingAnswer(
  Iterable<Confirmation> confirmations,
  Map<String, Receipt> receipts,
) {
  final list = [
    for (final c in confirmations)
      if (const {
        DealStage.waitingCollector,
        DealStage.notReceived,
      }.contains(dealStage(c, receipts[c.handoverId])))
        c,
  ];
  return list..sort((a, b) => a.confirmedAt.compareTo(b.confirmedAt));
}
