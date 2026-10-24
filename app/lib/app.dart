import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_placeholder_screen.dart';

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
