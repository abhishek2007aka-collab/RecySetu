import 'dart:convert';

import 'package:flutter/services.dart';

/// All user-facing text, read from `assets/i18n/<code>.json`.
///
/// Phase 2 extends this with the language registry and audio keys.
class AppStrings {
  AppStrings(this.languageCode, this._strings);

  final String languageCode;
  final Map<String, String> _strings;

  /// Returns the text for [key], or the key itself so a missing string is
  /// visible during development instead of crashing.
  String t(String key) => _strings[key] ?? key;

  /// Used by tests to compare language files.
  Set<String> get keysForTest => _strings.keys.toSet();

  factory AppStrings.fromJson(String languageCode, String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return AppStrings(languageCode, map.map((k, v) => MapEntry(k, '$v')));
  }

  static Future<AppStrings> load(
    String languageCode, {
    AssetBundle? bundle,
  }) async {
    final json = await (bundle ?? rootBundle).loadString(
      'assets/i18n/$languageCode.json',
    );
    return AppStrings.fromJson(languageCode, json);
  }
}
