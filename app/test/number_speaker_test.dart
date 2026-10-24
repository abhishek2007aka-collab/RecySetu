import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/audio/number_speaker.dart';

void main() {
  // Cases required by PLAN.md §6.6.
  const cases = <int, List<String>>{
    0: ['num/0'],
    7: ['num/7'],
    40: ['num/40'],
    99: ['num/99'],
    100: ['num/1', 'hundred'],
    340: ['num/3', 'hundred', 'num/40'],
    1000: ['num/1', 'thousand'],
    1340: ['num/1', 'thousand', 'num/3', 'hundred', 'num/40'],
    99999: ['num/99', 'thousand', 'num/9', 'hundred', 'num/99'],
    150000: ['num/1', 'lakh', 'num/50', 'thousand'],
  };

  cases.forEach((n, clips) {
    test('$n', () => expect(NumberSpeaker.clipsForNumber(n), clips));
  });

  test('1 crore says the lakh count as a number', () {
    expect(NumberSpeaker.clipsForNumber(10000000), [
      'num/1',
      'hundred',
      'lakh',
    ]);
  });

  test('rupee amounts are wrapped in about ... rupees', () {
    expect(NumberSpeaker.clipsForRupees(340), [
      'about',
      'num/3',
      'hundred',
      'num/40',
      'rupees',
    ]);
  });

  test('negative numbers are rejected', () {
    expect(() => NumberSpeaker.clipsForNumber(-1), throwsArgumentError);
  });
}
