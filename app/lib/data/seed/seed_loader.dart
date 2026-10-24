import 'dart:convert';

import 'package:flutter/services.dart';

/// Reads `assets/seed/<collection>.json`, made by `scripts/csv_to_assets.py`.
/// Used when Firestore has nothing yet (first run offline, or before login).
class SeedLoader {
  SeedLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<List<Map<String, dynamic>>> load(String collection) async {
    final json = await _bundle.loadString('assets/seed/$collection.json');
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }
}
