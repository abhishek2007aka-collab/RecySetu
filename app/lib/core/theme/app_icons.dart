import 'package:flutter/material.dart';

/// Built-in Material icons (Apache 2.0) used until the team draws its own.
/// A material's `iconAsset` is either one of these names or an
/// `assets/icons/...` image path.
abstract final class AppIcons {
  static const _byName = <String, IconData>{
    'memory': Icons.memory,
    'cable': Icons.cable,
    'battery_li': Icons.battery_charging_full,
    'battery_pb': Icons.car_repair,
    'tv': Icons.tv,
    'motor': Icons.settings,
    'plastic': Icons.local_drink,
    'phone': Icons.smartphone,
  };

  static Widget material(String iconAsset, {double size = 48, Color? color}) {
    if (iconAsset.startsWith('assets/')) {
      return Image.asset(iconAsset, width: size, height: size);
    }
    return Icon(
      _byName[iconAsset] ?? Icons.recycling,
      size: size,
      color: color,
    );
  }
}
