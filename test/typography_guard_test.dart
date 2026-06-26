import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'assert zero GoogleFonts.inter occurrences in lib/ (except core/theme/ and grandfathered files)',
      () {
    final dir = Directory('lib');
    final files = dir.listSync(recursive: true).whereType<File>().where((file) {
      final path = file.path.replaceAll('\\', '/');
      return path.endsWith('.dart') &&
          !path.contains('lib/core/theme/app_text.dart') &&
          !path.contains('lib/core/theme/app_theme.dart') &&
          !path.contains('splash_screen.dart') &&
          !path.contains('weekly_bar_chart.dart') &&
          !path.contains('routine_detail_styles.dart') &&
          !path.contains('app_error_screen.dart') &&
          !path.contains('bottom_nav_bar.dart') &&
          !path.contains('branded_line_chart.dart');
    });

    final List<String> failures = [];
    for (final file in files) {
      final content = file.readAsStringSync();
      if (content.contains('GoogleFonts.inter(')) {
        failures.add(file.path);
      }
    }

    expect(failures, isEmpty,
        reason:
            'Prohibited GoogleFonts.inter() used in these files:\n${failures.join('\n')}');
  });
}
