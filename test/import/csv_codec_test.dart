import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/import/data/csv_codec.dart';

void main() {
  group('CsvCodec.detectDelimiter', () {
    test('picks comma for a Hevy-style header', () {
      expect(CsvCodec.detectDelimiter('title,start_time,reps'), ',');
    });

    test('picks semicolon for a Strong-style header', () {
      expect(
        CsvCodec.detectDelimiter('Date;Workout Name;Exercise Name;Set Order'),
        ';',
      );
    });

    test('picks tab for a TSV header (Hevy Pro)', () {
      expect(CsvCodec.detectDelimiter('title\tstart_time\treps'), '\t');
    });

    test('ignores delimiters that appear only inside quotes', () {
      // Commas live inside the quoted title; the real delimiter is ';'.
      expect(
        CsvCodec.detectDelimiter('"A, B, C";Workout;Exercise'),
        ';',
      );
    });
  });

  group('CsvCodec.parse', () {
    test('strips a leading UTF-8 BOM', () {
      final rows = CsvCodec.parse('﻿a,b,c');
      expect(rows.single, ['a', 'b', 'c']);
    });

    test('keeps commas inside quoted fields', () {
      final rows = CsvCodec.parse('"Leg Day, Heavy",Squat,5');
      expect(rows.single, ['Leg Day, Heavy', 'Squat', '5']);
    });

    test('unescapes doubled quotes', () {
      final rows = CsvCodec.parse('"say ""hi""",x');
      expect(rows.single.first, 'say "hi"');
    });

    test('handles embedded newlines within quotes', () {
      final rows = CsvCodec.parse('"line1\nline2",b\nc,d');
      expect(rows.length, 2);
      expect(rows[0], ['line1\nline2', 'b']);
      expect(rows[1], ['c', 'd']);
    });

    test('handles CRLF line endings and drops blank lines', () {
      final rows = CsvCodec.parse('a,b\r\nc,d\r\n\r\n');
      expect(rows, [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('parses empty trailing cells', () {
      final rows = CsvCodec.parse('a,b,,', delimiter: ',');
      expect(rows.single, ['a', 'b', '', '']);
    });
  });
}
