/// Languages the app ships (PLAN.md §2). Each one has
/// `assets/i18n/<code>.json`; its own name lives in that file as `lang_name`.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.ttsLocale,
    required this.materialLocale,
  });

  final String code;

  /// Android text-to-speech locale, or null when only recorded clips exist.
  final String? ttsLocale;

  /// Locale given to Flutter's own widgets. Garhwali etc. have no Flutter
  /// locale data, so they use Hindi.
  final String materialLocale;
}

const appLanguages = <AppLanguage>[
  AppLanguage(code: 'hi', ttsLocale: 'hi-IN', materialLocale: 'hi'),
  AppLanguage(code: 'en', ttsLocale: 'en-IN', materialLocale: 'en'),
  AppLanguage(code: 'mr', ttsLocale: 'mr-IN', materialLocale: 'mr'),
  // LOCAL_1: Garhwali, chosen after the field study. Text is a Hindi copy
  // until translations arrive; audio comes from recorded clips only.
  AppLanguage(code: 'gbm', ttsLocale: null, materialLocale: 'hi'),
];

const defaultLanguage = 'hi';

AppLanguage languageByCode(String code) => appLanguages.firstWhere(
  (l) => l.code == code,
  orElse: () => appLanguages.first,
);
