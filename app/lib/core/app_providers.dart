import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n/app_strings.dart';
import 'i18n/languages.dart';

/// Filled in by `main()` before the app starts.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

/// Every language's strings, loaded once by `main()`.
final allStringsProvider = Provider<Map<String, AppStrings>>(
  (ref) => throw UnimplementedError(),
);

/// Whether `Firebase.initializeApp()` succeeded at startup.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// The chosen language code, saved on the phone.
final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<String> {
  static const _key = 'language';

  @override
  String build() =>
      ref.watch(sharedPrefsProvider).getString(_key) ?? defaultLanguage;

  void select(String code) {
    state = code;
    ref.read(sharedPrefsProvider).setString(_key, code);
  }
}

/// Text for the current language. Changing language rebuilds every screen.
final appStringsProvider = Provider<AppStrings>((ref) {
  final all = ref.watch(allStringsProvider);
  return all[ref.watch(languageProvider)] ?? all[defaultLanguage]!;
});
