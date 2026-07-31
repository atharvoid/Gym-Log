import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/import/import_service.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _busy = false;
  String? _status;
  ImportSummary? _summary;
  String? _error;

  Future<void> _pickAndImport() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Choose a backup file…';
      _summary = null;
      _error = null;
    });

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
          _error = "Couldn't open the file picker.";
        });
      }
      return;
    }

    if (result == null || result.files.single.path == null) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
      return;
    }

    final path = result.files.single.path!;
    setState(() => _status = 'Reading file…');

    try {
      final service = ref.read(importServiceProvider);
      final preview = await service.readAndValidate(path);

      if (!mounted) return;

      final confirmed = await showAppConfirmDialog(
        context: context,
        title: 'Import Backup?',
        message:
            'This will add ${preview.routineCount} routines and ${preview.sessionCount} workouts '
            'from ${preview.exportedAtLabel}. Existing data is preserved — duplicates are skipped.',
        confirmLabel: 'Import',
      );

      if (!confirmed) {
        setState(() {
          _busy = false;
          _status = null;
        });
        return;
      }

      setState(() => _status = 'Importing…');
      HapticFeedback.mediumImpact();

      final summary = await service.commitImport(preview);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = null;
        _summary = summary;
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = null;
        _error = "The import couldn't be completed. No partial data was kept "
            'for this file.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        title: Text('Import Backup',
            style: AppText.sectionHeading(color: surface.textPrimary)),
        backgroundColor: surface.bgBase,
        scrolledUnderElevation: 0,
        leading: BackButton(color: surface.textPrimary),
      ),
      // C32: this route (/settings/import) is pushed outside AppShell and
      // never opted into the AdaptiveContent width cap -- the summary/error
      // cards and Choose File button stretched edge-to-edge on
      // tablets/foldables.
      body: AdaptiveContent(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import a GymLog backup file exported from this or another device.',
                style: AppText.body(color: surface.textSecondary),
              ),
              const SizedBox(height: 24),
              if (_summary != null) _SummaryCard(summary: _summary!),
              if (_error != null) _ErrorCard(message: _error!),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(_status!, style: AppText.body(color: surface.textSecondary)),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _pickAndImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accent.base,
                    foregroundColor: context.accent.onAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.buttonPrimary)),
                  ),
                  child: Text('Choose File', style: AppText.button()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ImportSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Imported ${summary.routinesAdded} routines and ${summary.sessionsAdded} workouts.',
              style: AppText.body(color: surface.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppText.body(color: surface.textPrimary)),
          ),
        ],
      ),
    );
  }
}
