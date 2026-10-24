import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/i18n/app_strings.dart';

void main() {
  test('returns the text for a known key', () {
    final s = AppStrings.fromJson('en', '{"app_name": "Kabadiwala Connect"}');
    expect(s.t('app_name'), 'Kabadiwala Connect');
  });

  test('falls back to the key when text is missing', () {
    final s = AppStrings.fromJson('en', '{}');
    expect(s.t('nope'), 'nope');
  });

  test('hi.json and en.json have the same keys', () {
    Set<String> keys(String code) => AppStrings.fromJson(
      code,
      File('assets/i18n/$code.json').readAsStringSync(),
    ).keysForTest;
    expect(keys('en'), keys('hi'));
  });
}
