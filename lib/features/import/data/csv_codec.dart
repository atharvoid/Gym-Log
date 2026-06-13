/// A small, dependency-free CSV/TSV reader tuned for fitness-app exports.
///
/// Handles the quirks we actually see in Hevy and Strong files:
///   • delimiter auto-detection (comma, semicolon, or tab)
///   • RFC-4180 quoting, with `""` as an escaped quote
///   • embedded delimiters and newlines inside quoted fields
///   • a leading UTF-8 BOM
///   • both `\r\n` and `\n` (and lone `\r`) line endings
///
/// Pure Dart — no Flutter dependency, fully unit-testable.
library;

abstract final class CsvCodec {
  static const _candidates = [',', ';', '\t'];

  /// Detects the delimiter from the header line by counting candidate
  /// characters that occur OUTSIDE quotes. Falls back to comma.
  static String detectDelimiter(String text) {
    final line = _firstLine(_stripBom(text));
    var best = ',';
    var bestCount = -1;
    for (final d in _candidates) {
      final c = _countUnquoted(line, d);
      if (c > bestCount) {
        bestCount = c;
        best = d;
      }
    }
    return best;
  }

  /// Parses [text] into rows of string cells. If [delimiter] is null it is
  /// auto-detected from the header. Fully empty lines are dropped.
  static List<List<String>> parse(String text, {String? delimiter}) {
    final s = _stripBom(text);
    final delim = delimiter ?? detectDelimiter(s);
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    var fieldStarted = false;
    var rowHasContent = false;

    void endField() {
      row.add(field.toString());
      field = StringBuffer();
      fieldStarted = false;
    }

    void endRow() {
      endField();
      // Drop blank lines (a single empty field and nothing typed).
      if (rowHasContent) rows.add(row);
      row = <String>[];
      rowHasContent = false;
    }

    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < s.length && s[i + 1] == '"') {
            field.write('"');
            i++; // consume the escaped quote
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        if (ch == '"' && !fieldStarted) {
          inQuotes = true;
          fieldStarted = true;
          rowHasContent = true;
        } else if (ch == delim) {
          endField();
        } else if (ch == '\n') {
          endRow();
        } else if (ch == '\r') {
          if (i + 1 < s.length && s[i + 1] == '\n') i++; // CRLF
          endRow();
        } else {
          field.write(ch);
          fieldStarted = true;
          rowHasContent = true;
        }
      }
    }

    // Flush trailing field/row when the file doesn't end with a newline.
    if (rowHasContent || field.isNotEmpty || row.isNotEmpty) {
      endRow();
    }
    return rows;
  }

  static String _stripBom(String s) =>
      (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) ? s.substring(1) : s;

  static String _firstLine(String s) {
    final i = s.indexOf('\n');
    final line = i < 0 ? s : s.substring(0, i);
    return line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
  }

  static int _countUnquoted(String line, String delim) {
    var count = 0;
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes && ch == delim) {
        count++;
      }
    }
    return count;
  }
}
