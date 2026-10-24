import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/valuation/valuation.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';

Price _price(int lowRs, int highRs) => Price(
  materialCode: 'X',
  lowPaisePerKg: lowRs * 100,
  highPaisePerKg: highRs * 100,
);

void main() {
  test('PLAN example: 1.7 kg PCB at ₹180–220/kg -> about ₹340', () {
    final e = Valuation.estimate(1700, _price(180, 220));
    expect(e.lowPaise, 30600); // ₹306
    expect(e.highPaise, 37400); // ₹374
    expect(e.spokenRupees, 340);
  });

  test('rounds the spoken amount to the nearest ₹10', () {
    // 1 kg at ₹14–16 -> mid ₹15 -> ₹20 (half rounds up)
    expect(Valuation.estimate(1000, _price(14, 16)).spokenRupees, 20);
    // 1 kg at ₹13–15 -> mid ₹14 -> ₹10
    expect(Valuation.estimate(1000, _price(13, 15)).spokenRupees, 10);
  });

  test('zero weight is zero money', () {
    final e = Valuation.estimate(0, _price(180, 220));
    expect([e.lowPaise, e.highPaise, e.spokenRupees], [0, 0, 0]);
  });

  test('grams times paise never loses a paisa to decimals', () {
    // 333 g at ₹3/kg = 99.9 paise -> 100 (half up), not 99.89999
    expect(Valuation.paiseFor(333, 300), 100);
    expect(Valuation.paiseFor(1, 499), 0);
    expect(Valuation.paiseFor(1, 500), 1);
  });

  test('large lots stay exact (500 kg copper at ₹420/kg)', () {
    final e = Valuation.estimate(500000, _price(350, 420));
    expect(e.highPaise, 21000000); // ₹2,10,000
    expect(e.spokenRupees, 192500);
  });
}
