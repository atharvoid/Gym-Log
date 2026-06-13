// Pins the ONE axis-label formatter shared by every chart in the app.
//
// Regression guard for two real defects from the visual audit:
//   * "9.0k" — trailing .0 noise on round thousands (Profile weekly chart)
//   * Per-screen formatter drift — Routine Detail once rendered full
//     "3000/2000/1000" labels while Profile rendered "9.0k" for the same
//     visual element. One rule, every screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/branded_line_chart.dart';

void main() {
  group('BrandedLineChart.defaultAxisFormat', () {
    test('values under 1000 render as plain integers', () {
      expect(BrandedLineChart.defaultAxisFormat(0), '0');
      expect(BrandedLineChart.defaultAxisFormat(850), '850');
      expect(BrandedLineChart.defaultAxisFormat(999), '999');
    });

    test('round thousands compact with NO trailing .0', () {
      expect(BrandedLineChart.defaultAxisFormat(1000), '1k');
      expect(BrandedLineChart.defaultAxisFormat(3000), '3k');
      expect(BrandedLineChart.defaultAxisFormat(9000), '9k'); // was "9.0k"
      expect(BrandedLineChart.defaultAxisFormat(25000), '25k');
    });

    test('non-round thousands keep one decimal', () {
      expect(BrandedLineChart.defaultAxisFormat(1500), '1.5k');
      expect(BrandedLineChart.defaultAxisFormat(12500), '12.5k');
    });
  });
}
