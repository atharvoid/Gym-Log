import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/config/legal_links.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/app_info_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/shared/widgets/ui/app_action_row.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/branded_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gymlog/shared/layout/adaptive.dart';

/// Opens the Problem Report bottom sheet.
Future<void> showReportProblemSheet(BuildContext context, WidgetRef ref) async {
  HapticFeedback.lightImpact();

  final version = ref.read(appVersionProvider).valueOrNull ?? '1.0.0+1';
  const dbSchemaVersion = kDatabaseSchemaVersion;
  const catalogVersion = kExerciseCatalogVersion;
  final osName = kIsWeb
      ? 'Web'
      : Platform.isAndroid
          ? 'Android'
          : Platform.isIOS
              ? 'iOS'
              : Platform.operatingSystem;
  final opRef = 'op-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  await showBrandedBottomSheet<void>(
    context: context,
    title: 'Report a problem',
    subtitle: 'Submit non-sensitive diagnostic details to support',
    scrollable: true,
    child: ReportProblemForm(
      appVersion: version,
      dbSchemaVersion: dbSchemaVersion,
      catalogVersion: catalogVersion,
      osName: osName,
      opRef: opRef,
    ),
  );
}

class ReportProblemForm extends StatefulWidget {
  final String appVersion;
  final int dbSchemaVersion;
  final int catalogVersion;
  final String osName;
  final String opRef;

  const ReportProblemForm({
    super.key,
    required this.appVersion,
    required this.dbSchemaVersion,
    required this.catalogVersion,
    required this.osName,
    required this.opRef,
  });

  @override
  State<ReportProblemForm> createState() => _ReportProblemFormState();
}

class _ReportProblemFormState extends State<ReportProblemForm> {
  String _category = 'Bug / Crash';
  final _shortDescriptionController = TextEditingController();
  final _reproStepsController = TextEditingController();

  final List<String> _categories = [
    'Bug / Crash',
    'Sync Issue',
    'Exercise / Catalog',
    'Workout Tracker',
    'Personal Records',
    'Other',
  ];

  @override
  void dispose() {
    _shortDescriptionController.dispose();
    _reproStepsController.dispose();
    super.dispose();
  }

  String _buildDiagnosticReport() {
    final sb = StringBuffer();
    sb.writeln('--- GymLog Diagnostic Report ---');
    sb.writeln('Category: $_category');
    sb.writeln('Summary: ${_shortDescriptionController.text.trim()}');
    sb.writeln('Reproduction Steps: ${_reproStepsController.text.trim()}');
    sb.writeln('');
    sb.writeln('--- System Metadata ---');
    sb.writeln('App Version: ${widget.appVersion}');
    sb.writeln('OS: ${widget.osName}');
    sb.writeln('DB Schema Version: v${widget.dbSchemaVersion}');
    sb.writeln('Catalog Version: v${widget.catalogVersion}');
    sb.writeln('Op Reference: ${widget.opRef}');
    sb.writeln('');
    sb.writeln(
        'Privacy Guarantee: Workout history, emails, auth tokens, database payloads, and purchase tokens are excluded by default.');
    return sb.toString();
  }

  Future<void> _submitReport() async {
    if (_shortDescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a short description.')),
      );
      return;
    }

    final reportText = _buildDiagnosticReport();
    await Clipboard.setData(ClipboardData(text: reportText));

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      queryParameters: {
        'subject': 'GymLog Problem Report [$_category] (${widget.opRef})',
        'body': reportText,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await SharePlus.instance.share(
            ShareParams(text: reportText, subject: 'GymLog Problem Report'));
      }
    } catch (_) {
      await SharePlus.instance.share(
          ShareParams(text: reportText, subject: 'GymLog Problem Report'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('CATEGORY', style: AppText.meta(color: surface.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: surface.surface2,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              dropdownColor: surface.surface2,
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child:
                      Text(c, style: AppText.body(color: surface.textPrimary)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('SHORT DESCRIPTION',
            style: AppText.meta(color: surface.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _shortDescriptionController,
          style: AppText.body(color: surface.textPrimary),
          decoration: InputDecoration(
            hintText: 'What happened?',
            hintStyle: AppText.body(color: surface.textSecondary),
            filled: true,
            fillColor: surface.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('REPRODUCTION STEPS (OPTIONAL)',
            style: AppText.meta(color: surface.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _reproStepsController,
          maxLines: 3,
          style: AppText.body(color: surface.textPrimary),
          decoration: InputDecoration(
            hintText: '1. Tapped X\n2. Opened Y\n3. Saw error Z',
            hintStyle: AppText.body(color: surface.textSecondary),
            filled: true,
            fillColor: surface.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface.surface2,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SYSTEM METADATA (INCLUDED)',
                  style: AppText.meta(color: accent.base)),
              const SizedBox(height: 4),
              Text(
                'App: ${widget.appVersion} • OS: ${widget.osName} • DB: v${widget.dbSchemaVersion} • Catalog: v${widget.catalogVersion} • Ref: ${widget.opRef}',
                style: AppText.meta(color: surface.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Privacy Note: Workout contents, email, auth tokens, database payloads, and purchase tokens are strictly excluded.',
                style: AppText.caption(color: surface.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent.base,
              foregroundColor: accent.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
              ),
            ),
            child: Text('Submit Report',
                style: AppText.button(color: accent.onAccent)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Help & Feedback screen — canonical support identity and diagnostic portal.
class HelpFeedbackScreen extends ConsumerWidget {
  const HelpFeedbackScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (!tapGuard()) return;
    HapticFeedback.selectionClick();
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Could not open link'),
            content: Text('Link: $url'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = context.surface;
    final accent = context.accent;
    final version = ref.watch(appVersionProvider).valueOrNull ?? '1.0.0+1';

    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: surface.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Help & Feedback',
            style: AppText.screenTitle(color: surface.textPrimary)),
      ),
      body: AdaptiveContent(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.base.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.headset_mic_rounded,
                        color: accent.base, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GymLog Support',
                            style:
                                AppText.cardTitle(color: surface.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'Monitored route: $kSupportEmail',
                          style: AppText.meta(color: surface.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('SUPPORT & DIAGNOSTICS',
                style: AppText.meta(color: surface.textSecondary)),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppActionRow(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a problem',
                    subtitle: 'Send non-sensitive diagnostic report',
                    onTap: () => showReportProblemSheet(context, ref),
                  ),
                  const AppActionDivider(),
                  AppActionRow(
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact support',
                    subtitle: kSupportEmail,
                    onTap: () => _launchUrl(context, 'mailto:$kSupportEmail'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('LEGAL & PRIVACY',
                style: AppText.meta(color: surface.textSecondary)),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppActionRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Local-first. Zero ads, zero selling.',
                    onTap: () => _launchUrl(context, kPrivacyPolicyUrl),
                  ),
                  const AppActionDivider(),
                  AppActionRow(
                    icon: Icons.gavel_rounded,
                    title: 'Terms of Service',
                    subtitle: 'Subscription terms & data policies',
                    onTap: () => _launchUrl(context, kTermsOfServiceUrl),
                  ),
                  const AppActionDivider(),
                  AppActionRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Account Deletion',
                    subtitle: 'Web self-service deletion portal',
                    onTap: () => _launchUrl(context, kAccountDeletionUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                'GymLog $version • DB v$kDatabaseSchemaVersion • Catalog v$kExerciseCatalogVersion',
                style: AppText.caption(color: surface.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      )),
    );
  }
}
