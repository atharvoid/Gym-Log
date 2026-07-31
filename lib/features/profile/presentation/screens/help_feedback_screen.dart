import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:gymlog/shared/widgets/ui/app_action_row.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  void _snackLinkFailure(BuildContext context) {
    final surface = context.surface;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Couldn't open the link.",
            style: AppText.body(color: surface.textPrimary)),
        backgroundColor: surface.surface2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    HapticFeedback.lightImpact();
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _snackLinkFailure(context);
      }
    } catch (e) {
      if (context.mounted) {
        _snackLinkFailure(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        title: Text('Help & Feedback',
            style: AppText.sectionHeading(color: surface.textPrimary)),
        backgroundColor: surface.bgBase,
        scrolledUnderElevation: 0,
        leading: BackButton(color: surface.textPrimary),
      ),
      // C32: pushed as its own route, this screen never opted into the
      // AdaptiveContent width cap -- the action-row list stretched
      // edge-to-edge on tablets/foldables.
      body: AdaptiveContent(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              radius: AppRadius.card,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppActionRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    subtitle: 'FAQs and guides',
                    onTap: () =>
                        _launchUrl(context, 'https://gymlog.app/help'),
                  ),
                  const AppActionDivider(),
                  AppActionRow(
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact Support',
                    subtitle: 'support@gymlog.app',
                    onTap: () => _launchUrl(
                        context, 'mailto:support@gymlog.app'),
                  ),
                  const AppActionDivider(),
                  AppActionRow(
                    icon: Icons.star_outline_rounded,
                    title: 'Rate GymLog',
                    subtitle: 'Enjoying the app? Let us know',
                    onTap: () => _launchUrl(context,
                        'https://play.google.com/store/apps/details?id=com.gymlog.app'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
