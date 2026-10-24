import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kabadiwala_connect/core/app_providers.dart';
import 'package:kabadiwala_connect/core/audio/audio_service.dart';
import 'package:kabadiwala_connect/core/i18n/app_strings.dart';
import 'package:kabadiwala_connect/core/i18n/languages.dart';
import 'package:kabadiwala_connect/core/sync/sync_status.dart';
import 'package:kabadiwala_connect/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what would have been spoken, instead of using the TTS plugin.
class FakeAudio implements AudioService {
  final spoken = <String>[];
  var stops = 0;

  @override
  Future<void> speak(
    String lang,
    String key, [
    Map<String, Object> params = const {},
  ]) async => spoken.add(key);

  @override
  Future<void> stop() async => stops++;
}

/// The real language files from assets/i18n.
Map<String, AppStrings> realStrings() => {
  for (final l in appLanguages)
    l.code: AppStrings.fromJson(
      l.code,
      File('assets/i18n/${l.code}.json').readAsStringSync(),
    ),
};

Future<SharedPreferences> freshPrefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// A test app with Firebase off, real strings, fake audio and fake network.
Widget testApp(
  Widget child, {
  required SharedPreferences prefs,
  FakeAudio? audio,
  List overrides = const [],
  bool unsentData = false,
}) => ProviderScope(
  overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    allStringsProvider.overrideWithValue(realStrings()),
    audioServiceProvider.overrideWithValue(audio ?? FakeAudio()),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
    pendingWritesProvider.overrideWith((ref) => Stream.value(unsentData)),
    pendingCountProvider.overrideWith(
      (ref) => Stream.value(unsentData ? 2 : 0),
    ),
    ...overrides.cast(),
  ],
  child: MaterialApp(home: child),
);

/// A typical cheap phone: 360 x 780 dp.
void phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
