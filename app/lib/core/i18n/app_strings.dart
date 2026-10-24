import 'dart:convert';

import 'package:flutter/services.dart';

import 'languages.dart';

/// All user-facing text, read from `assets/i18n/<code>.json`.
/// Text may contain `{name}` slots, filled from `params`.
class AppStrings {
  AppStrings(this.languageCode, this._strings);

  final String languageCode;
  final Map<String, String> _strings;

  /// Returns the text for [key] with `{slots}` filled, or the key itself so
  /// a missing string is visible during development instead of crashing.
  String t(String key, [Map<String, Object> params = const {}]) {
    var text = _strings[key] ?? key;
    params.forEach(
      (name, value) => text = text.replaceAll('{$name}', '$value'),
    );
    return text;
  }

  bool has(String key) => _strings.containsKey(key);

  /// Every key in this language, sorted (used by the audio debug screen).
  List<String> get keys =>
      _strings.keys.where((k) => !k.startsWith('_')).toList()..sort();

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

  /// Loads every shipped language at startup (a few KB each) so switching
  /// language is instant.
  static Future<Map<String, AppStrings>> loadAll({AssetBundle? bundle}) async {
    final all = await Future.wait(
      appLanguages.map((l) => load(l.code, bundle: bundle)),
    );
    return {for (final s in all) s.languageCode: s};
  }
}
