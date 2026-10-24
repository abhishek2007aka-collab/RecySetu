import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/audio/audio_service.dart';
import 'package:kabadiwala_connect/core/i18n/app_strings.dart';

final _strings = {
  'hi': AppStrings('hi', const {
    'price_estimate': 'लगभग {amount} रुपये मिलेंगे',
  }),
  'mr': AppStrings('mr', const {
    'price_estimate': 'सुमारे {amount} रुपये मिळतील',
  }),
  'gbm': AppStrings('gbm', const {'price_estimate': 'गढ़वाली {amount}'}),
};

SpeechPlanner _planner({
  Set<String> clips = const {},
  Set<String> tts = const {},
}) => SpeechPlanner(
  strings: _strings,
  clipAssets: clips,
  ttsAvailable: tts.contains,
);

void main() {
  const params = {'amount': 340};

  test('1. recorded clips win, numbers composed first', () {
    final clips = {
      for (final c in [
        'price_estimate',
        'about',
        'num/3',
        'hundred',
        'num/40',
        'rupees',
      ])
        'assets/audio/gbm/$c.mp3',
    };
    final plan = _planner(clips: clips).plan('gbm', 'price_estimate', params);
    expect(plan, isA<ClipPlan>());
    expect((plan as ClipPlan).assets.first, 'assets/audio/gbm/about.mp3');
    expect(plan.assets.last, 'assets/audio/gbm/price_estimate.mp3');
  });

  test('a missing number clip falls through instead of half-playing', () {
    final clips = {'assets/audio/gbm/price_estimate.mp3'};
    final plan = _planner(clips: clips).plan('gbm', 'price_estimate', params);
    expect(plan, isA<TtsPlan>());
    expect((plan as TtsPlan).locale, 'hi-IN');
  });

  test('2. TTS in the chosen language when the phone has it', () {
    final plan = _planner(tts: {'mr-IN', 'hi-IN'})
        .plan('mr', 'price_estimate', params);
    expect((plan as TtsPlan).locale, 'mr-IN');
    expect(plan.text, 'सुमारे 340 रुपये मिळतील');
  });

  test('3. Hindi TTS when the language has no TTS voice', () {
    final plan = _planner(tts: {'hi-IN'}).plan('mr', 'price_estimate', params);
    expect((plan as TtsPlan).locale, 'hi-IN');
    expect(plan.text, 'लगभग 340 रुपये मिलेंगे');
  });
}
