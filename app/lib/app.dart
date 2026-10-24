import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_providers.dart';
import 'core/audio/audio_service.dart';
import 'core/i18n/languages.dart';
import 'core/theme/app_theme.dart';
import 'app_gate.dart';

class KabadiwalaApp extends ConsumerStatefulWidget {
  const KabadiwalaApp({super.key});

  @override
  ConsumerState<KabadiwalaApp> createState() => _KabadiwalaAppState();
}

class _KabadiwalaAppState extends ConsumerState<KabadiwalaApp> {
  late final _stopOnBack = StopSpeechOnBack(ref.stopSpeaking);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [_stopOnBack],
      onGenerateTitle: (_) => ref.read(appStringsProvider).t('brand'),
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
