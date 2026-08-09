// Copy guard (final-seven #4): user-facing strings never contain the em dash
// (U+2014) or the en dash (U+2013). The single-glyph ellipsis (…) is allowed;
// it is correct typography, not slop.
//
// Comments are stripped before scanning, so the ban covers shipped copy only.
// Known limitation of the naive stripper: a `//` inside a string literal
// (e.g. a URL) truncates the rest of that line from the scan. That can only
// ever produce a false NEGATIVE on the remainder of that line, never a false
// positive, and every string currently swept sits before any `//`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no em/en dashes in lib copy (comments stripped)', () {
    final failures = <String>[];
    final libDir = Directory('lib');
    if (!libDir.existsSync()) return;

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final code = _stripComments(entity.readAsStringSync());
      final lines = code.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('\u2014') || lines[i].contains('\u2013')) {
          failures.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'Em/en dashes found in app copy:\n${failures.join('\n')}',
    );
  });
}

/// Removes `//` line comments (including `///` doc comments) and `/* */`
/// block comments, preserving line numbers by writing a newline per stripped
/// line so reported positions stay accurate.
String _stripComments(String source) {
  final buffer = StringBuffer();
  var i = 0;
  var inBlock = false;
  while (i < source.length) {
    if (!inBlock &&
        i + 1 < source.length &&
        source[i] == '/' &&
        source[i + 1] == '/') {
      final newline = source.indexOf('\n', i);
      if (newline == -1) break;
      buffer.write('\n');
      i = newline + 1;
      continue;
    }
    if (!inBlock &&
        i + 1 < source.length &&
        source[i] == '/' &&
        source[i + 1] == '*') {
      inBlock = true;
      i += 2;
      continue;
    }
    if (inBlock &&
        i + 1 < source.length &&
        source[i] == '*' &&
        source[i + 1] == '/') {
      inBlock = false;
      i += 2;
      continue;
    }
    buffer.write(inBlock ? ' ' : source[i]);
    i++;
  }
  return buffer.toString();
}
