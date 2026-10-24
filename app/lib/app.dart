import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_placeholder_screen.dart';

/// Filled in by `main()` before the app starts.
final appStringsProvider = Provider<AppStrings>(
  (ref) => throw UnimplementedError(),
);

/// Whether `Firebase.initializeApp()` succeeded at startup.
final firebaseReadyProvider = Provider<bool>((ref) => false);

class KabadiwalaApp extends ConsumerWidget {
  const KabadiwalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (_) => ref.read(appStringsProvider).t('app_name'),
      theme: AppTheme.light(),
      home: const HomePlaceholderScreen(),
    );
  }
}
