import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n/app_strings.dart';

/// Filled in by `main()` before the app starts.
final appStringsProvider = Provider<AppStrings>(
  (ref) => throw UnimplementedError(),
);

/// Whether `Firebase.initializeApp()` succeeded at startup.
final firebaseReadyProvider = Provider<bool>((ref) => false);
