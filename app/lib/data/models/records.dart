import 'model_utils.dart';

/// Records created on the phone. IDs are UUIDs made on the device so the same
/// record written twice (offline retry) never becomes two records.
/// Weight in grams (int), money in paise (int), time in UTC.

enum UserRole { collector, recycler, admin }

enum LotStatus { draft, ready, handedOver }

enum HandoverStatus { pending, confirmed, disputed }

/// `due` (pay later) is no longer offered; kept only to read old records.
enum PaymentMode { cash, upi, due }

enum LedgerType { handover, soldElsewhere, manual }

String _lotWire(LotStatus s) =>
    s == LotStatus.handedOver ? 'handed_over' : s.name;
String _ledgerWire(LedgerType t) =>
    t == LedgerType.soldElsewhere ? 'sold_elsewhere' : t.name;

class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.phone,
    required this.language,
    required this.createdAt,
    this.name,
    this.recyclerId,
  });

  final String uid;
  final UserRole role;
  final String phone;
  final String language;
  final DateTime createdAt;
  final String? name;

  /// For recycler accounts: which `recyclers/{id}` they run.
  final String? recyclerId;

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
    uid: uid,
    role: readEnum(
      m['role'],
      UserRole.values,
      (r) => r.name,
      UserRole.collector,
    ),
    phone: m['phone'] as String? ?? '',
    language: m['language'] as String? ?? 'hi',
    createdAt: readTime(m['createdAt']) ?? DateTime.utc(1970),
    name: m['name'] as String?,
    recyclerId: m['recyclerId'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'role': role.name,
    'phone': phone,
    'language': language,
    'createdAt': writeTime(createdAt),
    'name': name,
    'recyclerId': recyclerId,
  };
}

class Lot {
  const Lot({
    required this.id,
    required this.collectorUid,
    required this.materialCode,
    required this.weightGrams,
    required this.estLowPaise,
    required this.estHighPaise,
    required this.createdAt,
    this.photoHashes = const [],
    this.photoUrls = const [],
    this.lat,
    this.lng,
    this.status = LotStatus.draft,
  });

  final String id;
  final String collectorUid;
  final String materialCode;
  final int weightGrams;
  final int estLowPaise;
  final int estHighPaise;
  final DateTime createdAt;

  /// SHA-256 (hex) of each compressed photo, computed at capture time.
  final List<String> photoHashes;
  final List<String> photoUrls;
  final double? lat;
  final double? lng;
  final LotStatus status;

  factory Lot.fromMap(String id, Map<String, dynamic> m) => Lot(
    id: id,
    collectorUid: m['collectorUid'] as String? ?? '',
    materialCode: m['materialCode'] as String? ?? '',
    weightGrams: readInt(m['weightGrams']) ?? 0,
    estLowPaise: readInt(m['estLowPaise']) ?? 0,
    estHighPaise: readInt(m['estHighPaise']) ?? 0,
    createdAt: readTime(m['createdAt']) ?? DateTime.utc(1970),
    photoHashes: readStringList(m['photoHashes']),
    photoUrls: readStringList(m['photoUrls']),
    lat: readDouble(m['lat']),
    lng: readDouble(m['lng']),
    status: readEnum(m['status'], LotStatus.values, _lotWire, LotStatus.draft),
  );

  Map<String, dynamic> toMap() => {
    'collectorUid': collectorUid,
    'materialCode': materialCode,
    'weightGrams': weightGrams,
    'estLowPaise': estLowPaise,
    'estHighPaise': estHighPaise,
    'createdAt': writeTime(createdAt),
    'photoHashes': photoHashes,
    'photoUrls': photoUrls,
    'lat': lat,
    'lng': lng,
    'status': _lotWire(status),
  };

  Lot copyWith({LotStatus? status, List<String>? photoUrls}) => Lot(
    id: id,
    collectorUid: collectorUid,
    materialCode: materialCode,
    weightGrams: weightGrams,
    estLowPaise: estLowPaise,
    estHighPaise: estHighPaise,
    createdAt: createdAt,
    photoHashes: photoHashes,
    photoUrls: photoUrls ?? this.photoUrls,
    lat: lat,
    lng: lng,
    status: status ?? this.status,
  );
}

/// Created by the collector at handover. The hash fields make it
/// tamper-evident (PLAN.md §6.4).
class Handover {
  const Handover({
    required this.id,
    required this.lotId,
    required this.collectorUid,
    required this.recyclerId,
    required this.materialCode,
    required this.weightGrams,
    required this.agreedPaise,
    required this.createdAt,
    required this.lat,
    required this.lng,
    required this.photosHash,
    required this.hash,
    this.status = HandoverStatus.pending,
  });

  final String id;
  final String lotId;
  final String collectorUid;
  final String recyclerId;
  final String materialCode;
  final int weightGrams;
  final int agreedPaise;
  final DateTime createdAt;
  final double lat;
  final double lng;
  final String photosHash;
  final String hash;
  final HandoverStatus status;

  factory Handover.fromMap(String id, Map<String, dynamic> m) => Handover(
    id: id,
    lotId: m['lotId'] as String? ?? '',
    collectorUid: m['collectorUid'] as String? ?? '',
    recyclerId: m['recyclerId'] as String? ?? '',
    materialCode: m['materialCode'] as String? ?? '',
    weightGrams: readInt(m['weightGrams']) ?? 0,
    agreedPaise: readInt(m['agreedPaise']) ?? 0,
    createdAt: readTime(m['createdAt']) ?? DateTime.utc(1970),
    lat: readDouble(m['lat']) ?? 0,
    lng: readDouble(m['lng']) ?? 0,
    photosHash: m['photosHash'] as String? ?? '',
    hash: m['hash'] as String? ?? '',
    status: readEnum(
      m['status'],
      HandoverStatus.values,
      (s) => s.name,
      HandoverStatus.pending,
    ),
  );

  Map<String, dynamic> toMap() => {
    'lotId': lotId,
    'collectorUid': collectorUid,
    'recyclerId': recyclerId,
    'materialCode': materialCode,
    'weightGrams': weightGrams,
    'agreedPaise': agreedPaise,
    'createdAt': writeTime(createdAt),
    'lat': lat,
    'lng': lng,
    'photosHash': photosHash,
    'hash': hash,
    'status': status.name,
  };
}

/// Written by the recycler after scanning the QR, in its own collection
/// (`confirmations/{handoverId}`). This works even when the collector's
/// handover has not reached the server yet (both phones may be offline).
class Confirmation {
  const Confirmation({
    required this.handoverId,
    required this.collectorUid,
    required this.recyclerId,
    required this.confirmedAt,
    required this.measuredWeightGrams,
    required this.amountPaise,
    required this.paidPaise,
    required this.paymentMode,
    this.flags = const [],
  });

  final String handoverId;
  final String collectorUid;
  final String recyclerId;
  final DateTime confirmedAt;
  final int measuredWeightGrams;

  /// Value of the deal for the measured weight.
  final int amountPaise;

  /// Money handed over now (0 when the mode is `due`).
  final int paidPaise;
  final PaymentMode paymentMode;

  /// e.g. `weight_mismatch`, `hash_mismatch`, `price_outlier`.
  final List<String> flags;

  bool get disputed => flags.contains('hash_mismatch');

  factory Confirmation.fromMap(String id, Map<String, dynamic> m) =>
      Confirmation(
        handoverId: id,
        collectorUid: m['collectorUid'] as String? ?? '',
        recyclerId: m['recyclerId'] as String? ?? '',
        confirmedAt: readTime(m['confirmedAt']) ?? DateTime.utc(1970),
        measuredWeightGrams: readInt(m['measuredWeightGrams']) ?? 0,
        amountPaise: readInt(m['amountPaise']) ?? readInt(m['paidPaise']) ?? 0,
        paidPaise: readInt(m['paidPaise']) ?? 0,
        paymentMode: readEnum(
          m['paymentMode'],
          PaymentMode.values,
          (p) => p.name,
          PaymentMode.due,
        ),
        flags: readStringList(m['flags']),
      );

  Map<String, dynamic> toMap() => {
    'collectorUid': collectorUid,
    'recyclerId': recyclerId,
    'confirmedAt': writeTime(confirmedAt),
    'measuredWeightGrams': measuredWeightGrams,
    'amountPaise': amountPaise,
    'paidPaise': paidPaise,
    'paymentMode': paymentMode.name,
    'flags': flags,
  };
}

/// Written by the collector (`receipts/{handoverId}`): "yes, I got the
/// money" or "no, not yet". A deal is complete only when [received] is true.
class Receipt {
  const Receipt({
    required this.handoverId,
    required this.collectorUid,
    required this.recyclerId,
    required this.received,
    required this.amountPaise,
    required this.answeredAt,
  });

  final String handoverId;
  final String collectorUid;
  final String recyclerId;
  final bool received;

  /// The amount the recycler said they paid, as seen by the collector.
  final int amountPaise;
  final DateTime answeredAt;

  factory Receipt.fromMap(String id, Map<String, dynamic> m) => Receipt(
    handoverId: id,
    collectorUid: m['collectorUid'] as String? ?? '',
    recyclerId: m['recyclerId'] as String? ?? '',
    received: m['received'] as bool? ?? false,
    amountPaise: readInt(m['amountPaise']) ?? 0,
    answeredAt: readTime(m['answeredAt']) ?? DateTime.utc(1970),
  );

  Map<String, dynamic> toMap() => {
    'collectorUid': collectorUid,
    'recyclerId': recyclerId,
    'received': received,
    'amountPaise': amountPaise,
    'answeredAt': writeTime(answeredAt),
  };
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.collectorUid,
    required this.type,
    required this.amountPaise,
    required this.paidPaise,
    required this.paymentMode,
    required this.createdAt,
    this.handoverId,
    this.materialCode,
    this.note = '',
  });

  final String id;
  final String collectorUid;
  final LedgerType type;
  final int amountPaise;
  final int paidPaise;
  final PaymentMode paymentMode;
  final DateTime createdAt;
  final String? handoverId;
  final String? materialCode;
  final String note;

  /// Money still owed to the collector.
  int get duePaise => amountPaise - paidPaise;

  factory LedgerEntry.fromMap(String id, Map<String, dynamic> m) => LedgerEntry(
    id: id,
    collectorUid: m['collectorUid'] as String? ?? '',
    type: readEnum(
      m['type'],
      LedgerType.values,
      _ledgerWire,
      LedgerType.manual,
    ),
    amountPaise: readInt(m['amountPaise']) ?? 0,
    paidPaise: readInt(m['paidPaise']) ?? 0,
    paymentMode: readEnum(
      m['paymentMode'],
      PaymentMode.values,
      (p) => p.name,
      PaymentMode.cash,
    ),
    createdAt: readTime(m['createdAt']) ?? DateTime.utc(1970),
    handoverId: m['handoverId'] as String?,
    materialCode: m['materialCode'] as String?,
    note: m['note'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'collectorUid': collectorUid,
    'type': _ledgerWire(type),
    'amountPaise': amountPaise,
    'paidPaise': paidPaise,
    'paymentMode': paymentMode.name,
    'createdAt': writeTime(createdAt),
    'handoverId': handoverId,
    'materialCode': materialCode,
    'note': note,
  };
}

enum ApplicationStatus { pending, approved, rejected }

/// A recycler asking to use recycler mode (`recycler_applications/{uid}`).
/// The team checks the authorisation number against the official CPCB/SPCB
/// list and approves it with scripts/approve_recycler.py.
class RecyclerApplication {
  const RecyclerApplication({
    required this.uid,
    required this.phone,
    required this.createdAt,
    this.recyclerId,
    this.businessName = '',
    this.authorisationRef = '',
    this.status = ApplicationStatus.pending,
  });

  final String uid;
  final String phone;
  final DateTime createdAt;

  /// Set when the applicant picked their business from the official list.
  final String? recyclerId;
  final String businessName;
  final String authorisationRef;
  final ApplicationStatus status;

  factory RecyclerApplication.fromMap(String uid, Map<String, dynamic> m) =>
      RecyclerApplication(
        uid: uid,
        phone: m['phone'] as String? ?? '',
        createdAt: readTime(m['createdAt']) ?? DateTime.utc(1970),
        recyclerId: m['recyclerId'] as String?,
        businessName: m['businessName'] as String? ?? '',
        authorisationRef: m['authorisationRef'] as String? ?? '',
        status: readEnum(
          m['status'],
          ApplicationStatus.values,
          (a) => a.name,
          ApplicationStatus.pending,
        ),
      );

  Map<String, dynamic> toMap() => {
    'phone': phone,
    'createdAt': writeTime(createdAt),
    'recyclerId': recyclerId,
    'businessName': businessName,
    'authorisationRef': authorisationRef,
    'status': status.name,
  };
}
