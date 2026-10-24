import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/i18n/languages.dart';
import '../../core/theme/app_theme.dart';
import 'session.dart';

/// S1. Tapping a language says its name (in that language); tapping the
/// same one again chooses it.
class LanguagePickScreen extends ConsumerStatefulWidget {
  const LanguagePickScreen({super.key});

  @override
  ConsumerState<LanguagePickScreen> createState() => _LanguagePickScreenState();
}

class _LanguagePickScreenState extends ConsumerState<LanguagePickScreen> {
  String? _heard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.speak('choose_language'),
    );
  }

  void _tap(String code) {
    if (_heard == code) {
      ref.read(sessionProvider.notifier).chooseLanguage(code);
      return;
    }
    setState(() => _heard = code);
    ref.read(languageProvider.notifier).select(code);
    ref.speak('lang_name');
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allStringsProvider);
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.translate, size: 36),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => ref.speak('choose_language'),
          ),
        ],
      ),
      body: SafeArea(
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            for (final l in appLanguages)
              _LanguageTile(
                name: all[l.code]!.t('lang_name'),
                heard: _heard == l.code,
                okLabel: s.t('ok'),
                onTap: () => _tap(l.code),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.name,
    required this.heard,
    required this.okLabel,
    required this.onTap,
  });

  final String name;
  final bool heard;
  final String okLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: heard
          ? AppColors.confirmed.withValues(alpha: 0.15)
          : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          width: 3,
          color: heard ? AppColors.confirmed : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              heard ? Icons.check_circle : Icons.volume_up,
              size: 40,
              color: heard ? AppColors.confirmed : scheme.primary,
            ),
            const SizedBox(height: 8),
            Text(name, style: Theme.of(context).textTheme.headlineMedium),
            if (heard)
              Text(okLabel, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
