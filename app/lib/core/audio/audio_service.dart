import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../app_providers.dart';
import '../i18n/app_strings.dart';
import '../i18n/languages.dart';
import 'number_speaker.dart';

/// What to play for one `speak` call.
sealed class SpeechPlan {
  const SpeechPlan();
}

class ClipPlan extends SpeechPlan {
  const ClipPlan(this.assets);
  final List<String> assets;
}

class TtsPlan extends SpeechPlan {
  const TtsPlan(this.locale, this.text);
  final String locale;
  final String text;
}

/// Decides how to say a string key (PLAN.md §2), with no plugins involved so
/// it can be unit-tested:
/// 1. A recorded clip exists for (language, key) -> play it. An `amount`
///    param (whole rupees) is played first from number clips:
///    "about 340 rupees" + the key's clip (e.g. "you will get").
/// 2. Android TTS has the language -> speak the translated text.
/// 3. Otherwise -> speak the Hindi text with Hindi TTS.
class SpeechPlanner {
  SpeechPlanner({
    required this.strings,
    required this.clipAssets,
    required this.ttsAvailable,
  });

  final Map<String, AppStrings> strings;
  final Set<String> clipAssets;
  final bool Function(String locale) ttsAvailable;

  SpeechPlan plan(
    String lang,
    String key, [
    Map<String, Object> params = const {},
  ]) {
    String clip(String name) => 'assets/audio/$lang/$name.mp3';

    if (clipAssets.contains(clip(key))) {
      final amount = params['amount'];
      final numberClips = amount is int
          ? NumberSpeaker.clipsForRupees(amount).map(clip).toList()
          : <String>[];
      if (numberClips.every(clipAssets.contains)) {
        return ClipPlan([...numberClips, clip(key)]);
      }
    }

    final locale = languageByCode(lang).ttsLocale;
    final local = strings[lang];
    if (locale != null && local != null && ttsAvailable(locale)) {
      return TtsPlan(locale, local.t(key, params));
    }
    return TtsPlan('hi-IN', strings[defaultLanguage]!.t(key, params));
  }
}

/// Plays speech. Every price must go through here (CLAUDE.md rule 3).
class AudioService {
  AudioService(this._strings);

  final Map<String, AppStrings> _strings;
  late final _tts = FlutterTts();
  late final _player = AudioPlayer();
  late final Future<SpeechPlanner> _planner = _init();

  Future<SpeechPlanner> _init() async {
    var clips = <String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      clips = manifest
          .listAssets()
          .where((a) => a.startsWith('assets/audio/'))
          .toSet();
    } catch (e) {
      debugPrint('audio manifest: $e');
    }

    final available = <String, bool>{};
    for (final lang in appLanguages) {
      final locale = lang.ttsLocale;
      if (locale == null) continue;
      try {
        available[locale] = await _tts.isLanguageAvailable(locale) == true;
      } catch (_) {
        available[locale] = false;
      }
    }
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('tts setup: $e');
    }

    return SpeechPlanner(
      strings: _strings,
      clipAssets: clips,
      ttsAvailable: (l) => available[l] ?? false,
    );
  }

  /// Says [key] in [lang]. Stops anything already playing first.
  Future<void> speak(
    String lang,
    String key, [
    Map<String, Object> params = const {},
  ]) async {
    final plan = (await _planner).plan(lang, key, params);
    await stop();
    try {
      switch (plan) {
        case ClipPlan(:final assets):
          await _player.setAudioSources([
            for (final a in assets) AudioSource.asset(a),
          ]);
          await _player.play();
        case TtsPlan(:final locale, :final text):
          await _tts.setLanguage(locale);
          await _tts.speak(text);
      }
    } catch (e) {
      debugPrint('speak $key: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      await _player.stop();
    } catch (e) {
      debugPrint('audio stop: $e');
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref.watch(allStringsProvider));
  ref.onDispose(service.stop);
  return service;
});

extension SpeakRef on WidgetRef {
  /// Says [key] in the current language.
  void speak(String key, [Map<String, Object> params = const {}]) {
    unawaited(
      read(audioServiceProvider).speak(read(languageProvider), key, params),
    );
  }
}
