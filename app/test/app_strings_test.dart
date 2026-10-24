import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/i18n/app_strings.dart';
import 'package:kabadiwala_connect/core/i18n/languages.dart';

Set<String> _keys(String code) => AppStrings.fromJson(
  code,
  File('assets/i18n/$code.json').readAsStringSync(),
).keysForTest.where((k) => !k.startsWith('_')).toSet();

void main() {
  test('returns the text for a known key', () {
    final s = AppStrings.fromJson('en', '{"app_name": "Kabadiwala Connect"}');
    expect(s.t('app_name'), 'Kabadiwala Connect');
  });

  test('falls back to the key when text is missing', () {
    final s = AppStrings.fromJson('en', '{}');
    expect(s.t('nope'), 'nope');
  });

  test('fills {slots} from params', () {
    final s = AppStrings('hi', const {'p': 'लगभग {amount} रुपये'});
    expect(s.t('p', {'amount': 340}), 'लगभग 340 रुपये');
  });

  test('every language file has exactly the Hindi keys', () {
    for (final lang in appLanguages) {
      expect(_keys(lang.code), _keys('hi'), reason: lang.code);
    }
  });

  test('every translation keeps the same {slots} as Hindi', () {
    final slot = RegExp(r'\{(\w+)\}');
    Map<String, String> raw(String code) => (jsonDecode(
      File('assets/i18n/$code.json').readAsStringSync(),
    ) as Map<String, dynamic>).map((k, v) => MapEntry(k, '$v'));
    final hi = raw('hi');
    for (final lang in appLanguages) {
      final other = raw(lang.code);
      for (final key in hi.keys.where((k) => !k.startsWith('_'))) {
        List<String> slots(String s) =>
            slot.allMatches(s).map((m) => m[1]!).toList()..sort();
        expect(
          slots(other[key]!),
          slots(hi[key]!),
          reason: '${lang.code}.$key',
        );
      }
    }
  });

  test('12 languages, each with its own name in its own script', () {
    expect(appLanguages, hasLength(12));
    final names = {
      for (final l in appLanguages)
        AppStrings.fromJson(
          l.code,
          File('assets/i18n/${l.code}.json').readAsStringSync(),
        ).t('lang_name'),
    };
    expect(names, hasLength(12));
  });
}
