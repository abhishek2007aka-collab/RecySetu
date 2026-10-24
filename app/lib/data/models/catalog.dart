import 'model_utils.dart';

/// Shared, admin-managed data: materials, prices, recyclers, areas.
/// Money is paise (int), never double.

enum Hazard { none, low, high }

/// A scrap category. Named ScrapMaterial to avoid clashing with Flutter's
/// `Material` widget.
class ScrapMaterial {
  const ScrapMaterial({
    required this.code,
    required this.nameKey,
    required this.iconAsset,
    required this.hazard,
    this.safetyCardIds = const [],
    this.placeholder = false,
  });

  final String code;
  final String nameKey;

  /// Either an `assets/...` image path or a built-in icon name (see AppIcons).
  final String iconAsset;
  final Hazard hazard;
  final List<String> safetyCardIds;
  final bool placeholder;

  factory ScrapMaterial.fromMap(Map<String, dynamic> m) => ScrapMaterial(
    code: m['code'] as String,
    nameKey: m['nameKey'] as String? ?? 'mat_${m['code']}',
    iconAsset: m['iconAsset'] as String? ?? '',
    hazard: readEnum(m['hazard'], Hazard.values, (h) => h.name, Hazard.none),
    safetyCardIds: readStringList(m['safetyCardIds']),
    placeholder: m['placeholder'] == true,
  );

  Map<String, dynamic> toMap() => {
    'code': code,
    'nameKey': nameKey,
    'iconAsset': iconAsset,
    'hazard': hazard.name,
    'safetyCardIds': safetyCardIds,
    'placeholder': placeholder,
  };
}

class Price {
  const Price({
    required this.materialCode,
    required this.lowPaisePerKg,
    required this.highPaisePerKg,
    this.weekAgoMidPaisePerKg,
    this.updatedAt,
    this.source = 'field_study',
    this.placeholder = false,
  });

  final String materialCode;
  final int lowPaisePerKg;
  final int highPaisePerKg;
  final int? weekAgoMidPaisePerKg;
  final DateTime? updatedAt;
  final String source;
  final bool placeholder;

  factory Price.fromMap(Map<String, dynamic> m) => Price(
    materialCode: m['materialCode'] as String,
    lowPaisePerKg: readInt(m['currentLowPaisePerKg']) ?? 0,
    highPaisePerKg: readInt(m['currentHighPaisePerKg']) ?? 0,
    weekAgoMidPaisePerKg: readInt(m['weekAgoMidPaisePerKg']),
    updatedAt: readTime(m['updatedAt']),
    source: m['source'] as String? ?? 'field_study',
    placeholder: m['placeholder'] == true,
  );

  Map<String, dynamic> toMap() => {
    'materialCode': materialCode,
    'currentLowPaisePerKg': lowPaisePerKg,
    'currentHighPaisePerKg': highPaisePerKg,
    'weekAgoMidPaisePerKg': weekAgoMidPaisePerKg,
    'updatedAt': writeTime(updatedAt),
    'source': source,
    'placeholder': placeholder,
  };
}

class Recycler {
  const Recycler({
    required this.id,
    required this.name,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.address,
    required this.authorised,
    required this.authorisationRef,
    required this.offersPickup,
    required this.ratesPaisePerKg,
    this.ownerUid,
    this.ownerPhone,
    this.placeholder = false,
  });

  final String id;
  final String name;
  final String phone;
  final double lat;
  final double lng;
  final String address;
  final bool authorised;
  final String authorisationRef;
  final bool offersPickup;
  final Map<String, int> ratesPaisePerKg;

  /// Login of the recycler's own account; set when they first sign in.
  final String? ownerUid;

  /// Phone number invited to run this recycler in recycler mode.
  final String? ownerPhone;
  final bool placeholder;

  factory Recycler.fromMap(Map<String, dynamic> m) => Recycler(
    id: m['id'] as String,
    name: m['name'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    lat: readDouble(m['lat']) ?? 0,
    lng: readDouble(m['lng']) ?? 0,
    address: m['address'] as String? ?? '',
    authorised: m['authorised'] == true,
    authorisationRef: m['authorisationRef'] as String? ?? '',
    offersPickup: m['offersPickup'] == true,
    ratesPaisePerKg: {
      for (final e in ((m['ratesPaisePerKg'] as Map?) ?? const {}).entries)
        if (readInt(e.value) != null) '${e.key}': readInt(e.value)!,
    },
    ownerUid: m['ownerUid'] as String?,
    ownerPhone: m['ownerPhone'] as String?,
    placeholder: m['placeholder'] == true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'lat': lat,
    'lng': lng,
    'address': address,
    'authorised': authorised,
    'authorisationRef': authorisationRef,
    'offersPickup': offersPickup,
    'ratesPaisePerKg': ratesPaisePerKg,
    'ownerUid': ownerUid,
    'ownerPhone': ownerPhone,
    'placeholder': placeholder,
  };
}

/// A pickable area, used when the collector refuses location permission.
class Area {
  const Area({
    required this.id,
    required this.nameKey,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String nameKey;
  final double lat;
  final double lng;

  factory Area.fromMap(Map<String, dynamic> m) => Area(
    id: m['id'] as String,
    nameKey: m['nameKey'] as String? ?? m['id'] as String,
    lat: readDouble(m['lat']) ?? 0,
    lng: readDouble(m['lng']) ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nameKey': nameKey,
    'lat': lat,
    'lng': lng,
  };
}
