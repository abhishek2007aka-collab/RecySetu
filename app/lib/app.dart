import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_providers.dart';
import 'core/i18n/languages.dart';
import 'core/theme/app_theme.dart';
import 'app_gate.dart';

class KabadiwalaApp extends ConsumerWidget {
  const KabadiwalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (_) => ref.read(appStringsProvider).t('app_name'),
      theme: AppTheme.light(),
      // Urdu is written right-to-left: mirror the whole layout.
      builder: (context, child) => Directionality(
        textDirection: languageByCode(ref.watch(languageProvider)).rtl
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child!,
      ),
      home: const AppGate(),
    );
  }
}
