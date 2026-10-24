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
}
