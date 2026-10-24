import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../app_providers.dart';
import 'geo.dart';

/// The collector's last known place: from GPS, or an area they picked when
/// they did not want to share location. Saved on the phone, so it works
/// offline (GPS itself needs no internet).
class MyLocationNotifier extends Notifier<LatLng?> {
  static const _lat = 'my_lat';
  static const _lng = 'my_lng';

  @override
  LatLng? build() {
    final p = ref.watch(sharedPrefsProvider);
    final lat = p.getDouble(_lat);
    final lng = p.getDouble(_lng);
    return lat == null || lng == null ? null : (lat: lat, lng: lng);
  }

  void set(LatLng where) {
    final p = ref.read(sharedPrefsProvider);
    p.setDouble(_lat, where.lat);
    p.setDouble(_lng, where.lng);
    state = where;
  }

  /// Asks permission if needed, then reads GPS. Returns false if refused or
  /// no fix could be found; the caller then offers the area list.
  Future<bool> fromGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return false;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return false;
      set((lat: pos.latitude, lng: pos.longitude));
      return true;
    } catch (e) {
      debugPrint('location: $e');
      return false;
    }
  }
}

final myLocationProvider = NotifierProvider<MyLocationNotifier, LatLng?>(
  MyLocationNotifier.new,
);
