import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/i18n/languages.dart';
import '../../core/theme/app_theme.dart';
import 'session.dart';

/// S1. Tapping a language says its name (in that language); tapping the
/// same one again chooses it. First page: 3 featured languages + "more",
/// so the screen keeps to 4 choices (CLAUDE.md rule 2).
class LanguagePickScreen extends ConsumerStatefulWidget {
  const LanguagePickScreen({super.key, this.changing = false});

  /// True when opened from home to change language: choosing goes back.
  final bool changing;

  @override
  ConsumerState<LanguagePickScreen> createState() => _LanguagePickScreenState();
}

class _LanguagePickScreenState extends ConsumerState<LanguagePickScreen> {
  String? _heard;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.speak('choose_language', const {}, true),
    );
  }

  void _tap(String code) {
    if (_heard == code) {
      if (widget.changing) {
        ref.read(languageProvider.notifier).select(code);
        Navigator.of(context).pop();
      } else {
        ref.read(sessionProvider.notifier).chooseLanguage(code);
      }
      return;
    }
    setState(() => _heard = code);
    ref.read(languageProvider.notifier).select(code);
    ref.speak('lang_name', const {}, true);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allStringsProvider);
    final s = ref.watch(appStringsProvider);
    final shown = _showAll
        ? appLanguages
        : [for (final c in featuredLanguages) languageByCode(c)];

    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.translate, size: 36),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => ref.speak('choose_language', const {}, true),
          ),
        ],
      ),
      body: SafeArea(
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: _showAll ? 1.4 : 1,
          children: [
            for (final l in shown)
              _LanguageTile(
                name: all[l.code]!.t('lang_name'),
                heard: _heard == l.code,
                okLabel: s.t('ok'),
                onTap: () => _tap(l.code),
              ),
            if (!_showAll)
              _MoreTile(
                label: s.t('more_languages'),
                onTap: () {
                  setState(() => _showAll = true);
                  ref.speak('more_languages', const {}, true);
                },
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
            FittedBox(
              child: Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (heard)
              Text(okLabel, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.language, size: 48),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    ),
  );
}

/// Top-bar button that opens the language screen to change language later.
class ChangeLanguageButton extends ConsumerWidget {
  const ChangeLanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.translate),
    tooltip: ref.watch(appStringsProvider).t('change_language'),
    onPressed: () {
      ref.speak('change_language');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LanguagePickScreen(changing: true),
        ),
      );
    },
  );
}
