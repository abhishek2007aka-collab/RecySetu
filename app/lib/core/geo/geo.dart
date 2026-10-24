import 'dart:math' as math;

/// A point on the map, in degrees.
typedef LatLng = ({double lat, double lng});

/// Straight-line distance in km (haversine formula). Good enough for
/// "which recycler is nearer"; we do not use a maps SDK (PLAN.md §1).
double haversineKm(LatLng a, LatLng b) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.sqrt(h));
}
