import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/geo/geo.dart';
import 'package:kabadiwala_connect/core/geo/recycler_ranking.dart';
import 'package:kabadiwala_connect/core/valuation/trend.dart';
import 'package:kabadiwala_connect/data/models/catalog.dart';

Price _p(int low, int high, int? weekAgoMid) => Price(
  materialCode: 'X',
  lowPaisePerKg: low,
  highPaisePerKg: high,
  weekAgoMidPaisePerKg: weekAgoMid,
);

Recycler _r(
  String id, {
  double lat = 29.8543,
  double lng = 77.8880,
  bool authorised = true,
  bool pickup = false,
  Map<String, int> rates = const {'PCB': 20000},
}) => Recycler(
  id: id,
  name: id,
  phone: '',
  lat: lat,
  lng: lng,
  address: '',
  authorised: authorised,
  authorisationRef: '',
  offersPickup: pickup,
  ratesPaisePerKg: rates,
);

const LatLng roorkee = (lat: 29.8543, lng: 77.8880);

void main() {
  group('trend (§6.2)', () {
    test('up above +5%, down below −5%, flat in between', () {
      expect(trendFor(_p(10000, 12000, 10000)), Trend.up); // mid 110 vs 100
      // Exactly −5% is not "less than −5%", so still flat.
      expect(trendFor(_p(9000, 10000, 10000)), Trend.flat);
      expect(trendFor(_p(9000, 9900, 10000)), Trend.down); // mid 94.5
      expect(trendFor(_p(8000, 10000, 10000)), Trend.down); // mid 90
      expect(
        trendFor(_p(10000, 11000, 10000)),
        Trend.flat,
      ); // mid 105 -> exactly +5%
      expect(trendFor(_p(10000, 10000, 10000)), Trend.flat);
    });
    test('unknown last week is flat', () {
      expect(trendFor(_p(10000, 12000, null)), Trend.flat);
      expect(trendFor(_p(10000, 12000, 0)), Trend.flat);
    });
  });

  group('distance', () {
    test('same point is 0 km', () {
      expect(haversineKm(roorkee, roorkee), 0);
    });
    test('Roorkee to Dehradun is about 55 km', () {
      final km = haversineKm(roorkee, (lat: 30.3165, lng: 78.0322));
      expect(km, closeTo(53, 4));
    });
  });

  group('ranking (§6.3)', () {
    test('hides unauthorised; unknown rates are listed after known ones', () {
      final ranked = rankRecyclers(
        recyclers: [
          _r('norate', rates: {'CRT': 5000}),
          _r('ok'),
          _r('unauth', authorised: false, rates: {'PCB': 99999}),
          _r('zero', rates: {'PCB': 0}),
        ],
        materialCode: 'PCB',
        from: roorkee,
      );
      expect(ranked.map((r) => r.recycler.id), ['ok', 'norate', 'zero']);
      expect(ranked[1].ratePaisePerKg, isNull);
      // Unknown rate scores on distance only: 0.35 at 0 km.
      expect(ranked[1].score, closeTo(0.35, 1e-9));
    });

    test('best rate + near + pickup wins; score matches the formula', () {
      final ranked = rankRecyclers(
        recyclers: [
          _r('far_high', lat: 30.3165, lng: 78.0322, rates: {'PCB': 22000}),
          _r('near_pickup', pickup: true, rates: {'PCB': 20000}),
        ],
        materialCode: 'PCB',
        from: roorkee,
      );
      expect(ranked.first.recycler.id, 'near_pickup');
      // 0.45 × 20000/22000 + 0.35 × 1 + 0.20 × 1
      expect(ranked.first.score, closeTo(0.45 * 20 / 22 + 0.55, 1e-9));
      // far_high is beyond the 25 km cap: distance score 0
      expect(ranked.last.score, closeTo(0.45, 1e-9));
    });

    test('distance is capped at 25 km', () {
      final ranked = rankRecyclers(
        recyclers: [
          _r('30km', lat: 29.8543 + 0.27),
          _r('60km', lat: 29.8543 + 0.54),
        ],
        materialCode: 'PCB',
        from: roorkee,
      );
      expect(ranked[0].score, ranked[1].score);
      // Equal score and rate: the nearer one comes first.
      expect(ranked.first.recycler.id, '30km');
    });

    test('exact ties are ordered by id, so the list never jumps', () {
      final ranked = rankRecyclers(
        recyclers: [_r('b'), _r('a'), _r('c')],
        materialCode: 'PCB',
        from: roorkee,
      );
      expect(ranked.map((r) => r.recycler.id), ['a', 'b', 'c']);
    });

    test('shows at most 5', () {
      final ranked = rankRecyclers(
        recyclers: [for (var i = 0; i < 8; i++) _r('r$i')],
        materialCode: 'PCB',
        from: roorkee,
      );
      expect(ranked, hasLength(5));
    });

    test('nothing to rank gives an empty list', () {
      expect(
        rankRecyclers(recyclers: const [], materialCode: 'PCB', from: roorkee),
        isEmpty,
      );
    });
  });
}
