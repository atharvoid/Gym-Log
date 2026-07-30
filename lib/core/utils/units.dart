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

/// Short display label for the active weight unit: "kg" or "lbs".
///
/// Single source of truth for the literal, so no screen can drift to "KG",
/// "lb" or "pounds" on its own.
String unitLabel(String unit) => unit == 'lbs' ? 'lbs' : 'kg';

/// Aggregate volume (the sum of weight × reps across sets, a session or a
/// week). Stored in kilograms like every other weight in the DB, so it must be
/// converted at the display boundary exactly like a per-set weight is:
/// "12,450 kg" / "27,447 lbs".
///
/// Use this for EVERY aggregate-volume figure in the app. Before this helper
/// existed the per-set path went through [formatWeight] while every aggregate
/// path appended its own hardcoded "kg", so a user on pounds saw converted set
/// weights and unconverted, mislabelled totals on the same screen.
///
/// Note for chart callers: this formats a value that is still in kilograms.
/// If the plotted series itself has already been converted with [kgToDisplay]
/// (which it must be, so the axis ticks match the header), format that series
/// with `groupThousands(v)` + [unitLabel] instead — do NOT convert twice.
String formatVolume(double kg, String unit) =>
    '${groupThousands(kgToDisplay(kg, unit))} ${unitLabel(unit)}';
