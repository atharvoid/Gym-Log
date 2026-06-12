/// Weight-unit conversion at the display/input boundary.
///
/// The database stores kilograms, always — unit preference is presentation
/// only, so historical data can never be corrupted by a settings change.
library;

const kgPerLb = 0.45359237;

double kgToDisplay(double kg, String unit) => unit == 'lbs' ? kg / kgPerLb : kg;

double displayToKg(double value, String unit) =>
    unit == 'lbs' ? value * kgPerLb : value;

String formatWeight(double kg, String unit, {int maxDecimals = 1}) {
  final v = kgToDisplay(kg, unit);
  if (v == v.truncateToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(maxDecimals);
}

/// "12,450" — full notation with thousands separators, no compact suffix.
/// (Compact "3.0k" + a unit label reads as a double unit: "3.0k kg".)
String groupThousands(num value) {
  final s = value.round().toString();
  final negative = s.startsWith('-');
  final digits = negative ? s.substring(1) : s;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buf';
}
