import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/config/legal_links.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/features/profile/presentation/screens/help_feedback_screen.dart';

void main() {
  group('ATOMIC-13 Documentation & Support Metadata Qualification', () {
    test('canonical support email and legal URLs are defined and valid', () {
      expect(kSupportEmail, equals('support@gymlog.app'));
      expect(kPrivacyPolicyUrl, contains('privacy-policy.html'));
      expect(kTermsOfServiceUrl, contains('terms-of-service.html'));
      expect(kAccountDeletionUrl, contains('delete-account.html'));
    });

    test('database schema version matches code specification', () {
      expect(kDatabaseSchemaVersion, equals(5));
    });

    test('documentation files exist and contain document authority headers',
        () {
      final docFiles = [
        'README.md',
        'docs/README.md',
        'docs/ARCHITECTURE.md',
        'docs/CONVENTIONS.md',
        'docs/DATA_MODEL.md',
        'docs/SYNC_DESIGN.md',
        'docs/ACCOUNT_ISOLATION.md',
        'docs/REVENUECAT_CONFIG.md',
        'docs/DESIGN_NORTH_STAR.md',
        'docs/CI_RUNBOOK.md',
        'docs/IMPORT.md',
        'docs/CONSOLE_CHECKLIST.md',
        'docs/STORE_LISTING.md',
        'docs/legal/PRIVACY_POLICY.md',
        'docs/legal/TERMS_OF_SERVICE.md',
        'docs/legal/DEPENDENCY_LICENSE_INVENTORY.md',
      ];

      for (final relativePath in docFiles) {
        final file = File(relativePath);
        expect(file.existsSync(), isTrue,
            reason: 'File $relativePath should exist');

        final content = file.readAsStringSync();
        expect(content, contains('**Status:**'),
            reason: '$relativePath missing Status');
        expect(content, contains('**Owner:**'),
            reason: '$relativePath missing Owner');
        expect(content, contains('**Last verified SHA:**'),
            reason: '$relativePath missing Last verified SHA');
      }
    });

    test('DATA_MODEL.md contains correct schema version 5', () {
      final file = File('docs/DATA_MODEL.md');
      final content = file.readAsStringSync();
      expect(content, contains('Schema version: **5**'));
    });

    testWidgets('HelpFeedbackScreen renders support identity and action rows',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpFeedbackScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Help & Feedback'), findsOneWidget);
      expect(find.text('Monitored route: support@gymlog.app'), findsOneWidget);
      expect(find.text('Report a problem'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets(
        'Tapping Report a problem opens problem report sheet with system metadata',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpFeedbackScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final reportRow = find.text('Report a problem');
      expect(reportRow, findsOneWidget);
      await tester.tap(reportRow);
      await tester.pumpAndSettle();

      expect(find.text('Submit non-sensitive diagnostic details to support'),
          findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('SHORT DESCRIPTION'), findsOneWidget);
      expect(find.text('SYSTEM METADATA (INCLUDED)'), findsOneWidget);
      expect(find.textContaining('DB: v5'), findsOneWidget);
      expect(find.textContaining('Catalog: v2'), findsOneWidget);
    });
  });
}
