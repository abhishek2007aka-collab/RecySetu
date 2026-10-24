/// Languages the app ships (PLAN.md §2). Each one has
/// `assets/i18n/<code>.json`; its own name lives in that file as `lang_name`.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.ttsLocale,
    required this.materialLocale,
    this.rtl = false,
  });

  final String code;

  /// Android text-to-speech locale, or null when only recorded clips exist
  /// (then the Hindi voice is used until clips are recorded).
  final String? ttsLocale;

  /// Locale given to Flutter's own widgets. Languages without Flutter locale
  /// data (Garhwali, Bhojpuri) use Hindi.
  final String materialLocale;

  /// Written right-to-left (Urdu).
  final bool rtl;
}

const appLanguages = <AppLanguage>[
  AppLanguage(code: 'hi', ttsLocale: 'hi-IN', materialLocale: 'hi'),
  // LOCAL_1: Garhwali, chosen for Uttarakhand. Text is a Hindi copy until
  // translations arrive; audio comes from recorded clips only.
  AppLanguage(code: 'gbm', ttsLocale: null, materialLocale: 'hi'),
  AppLanguage(code: 'mr', ttsLocale: 'mr-IN', materialLocale: 'mr'),
  AppLanguage(code: 'en', ttsLocale: 'en-IN', materialLocale: 'en'),
  AppLanguage(code: 'bn', ttsLocale: 'bn-IN', materialLocale: 'bn'),
  // LOCAL_2: Bhojpuri (Devanagari). Android has no Bhojpuri voice.
  AppLanguage(code: 'bho', ttsLocale: null, materialLocale: 'hi'),
  AppLanguage(code: 'pa', ttsLocale: 'pa-IN', materialLocale: 'pa'),
  AppLanguage(code: 'ur', ttsLocale: 'ur-IN', materialLocale: 'ur', rtl: true),
  AppLanguage(code: 'gu', ttsLocale: 'gu-IN', materialLocale: 'gu'),
  AppLanguage(code: 'ta', ttsLocale: 'ta-IN', materialLocale: 'ta'),
  AppLanguage(code: 'te', ttsLocale: 'te-IN', materialLocale: 'te'),
  AppLanguage(code: 'kn', ttsLocale: 'kn-IN', materialLocale: 'kn'),
];

/// Shown first on the language screen (with a "more languages" tile, so the
/// screen keeps to 4 choices). Set these from the field study's region.
const featuredLanguages = ['hi', 'gbm', 'mr'];

const defaultLanguage = 'hi';

AppLanguage languageByCode(String code) => appLanguages.firstWhere(
  (l) => l.code == code,
  orElse: () => appLanguages.first,
);
