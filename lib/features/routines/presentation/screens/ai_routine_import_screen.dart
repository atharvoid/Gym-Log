import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/routines/presentation/providers/ai_routine_import_provider.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/segmented_control.dart';

/// Screen for capturing photos or pasting text to import a routine with AI.
class AiRoutineImportScreen extends ConsumerStatefulWidget {
  const AiRoutineImportScreen({super.key});

  @override
  ConsumerState<AiRoutineImportScreen> createState() =>
      _AiRoutineImportScreenState();
}

class _AiRoutineImportScreenState extends ConsumerState<AiRoutineImportScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  String _selectedMode = 'Photo / Image';

  static const _modes = ['Photo / Image', 'Paste Text'];

  @override
  void initState() {
    super.initState();
    final currentText = ref.read(aiRoutineImportProvider).textInput;
    if (currentText.isNotEmpty) {
      _textController.text = currentText;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      ref.read(aiRoutineImportProvider.notifier).setImage(bytes, file.name);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load selected image.')),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _textController.text = data.text!.trim();
      ref
          .read(aiRoutineImportProvider.notifier)
          .setTextInput(_textController.text);
    }
  }

  Future<void> _handleAnalyze() async {
    FocusScope.of(context).unfocus();
    if (_selectedMode == 'Paste Text') {
      ref
          .read(aiRoutineImportProvider.notifier)
          .setTextInput(_textController.text);
    }

    final success = await ref.read(aiRoutineImportProvider.notifier).analyze();

    if (success && mounted) {
      context.push('/routines/ai-import/review');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiRoutineImportProvider);
    final surface = context.surface;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI Routine Import',
          style: AppText.sheetTitle(color: surface.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode selector
                    SegmentedControl(
                      segments: _modes,
                      selected: _selectedMode,
                      onChanged: (mode) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMode = mode);
                      },
                    ),
                    const SizedBox(height: 20),

                    if (_selectedMode == 'Photo / Image')
                      _buildImageSection(state)
                    else
                      _buildTextSection(state),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(state.errorMessage!),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: state.status == AiImportStatus.compressing
                        ? 'Optimizing image...'
                        : state.status == AiImportStatus.analyzing
                            ? 'Analyzing routine with AI...'
                            : 'Analyze Routine',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: state.isLoading,
                    onPressed: state.canAnalyze ? _handleAnalyze : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will review and verify all exercises before saving.',
                    style: AppText.caption(color: surface.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(AiRoutineImportState state) {
    final surface = context.surface;
    final accent = context.accent;

    if (state.selectedImageBytes != null) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                height: 220,
                color: surface.surface2,
                child: Image.memory(
                  state.selectedImageBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.selectedImageName ?? 'Workout Image',
                    style: AppText.exerciseName(color: surface.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon:
                      Icon(Icons.refresh_rounded, size: 16, color: accent.base),
                  label: Text('Change', style: TextStyle(color: accent.base)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.white70),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(aiRoutineImportProvider.notifier).clearImage();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: surface.surface3,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.document_scanner_outlined,
                size: 30, color: accent.base),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload a Photo or Screenshot',
            style: AppText.sheetTitle(color: surface.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo of a whiteboard, notebook, or upload a screenshot from any workout app.',
            style: AppText.body(color: surface.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: surface.textPrimary,
                    side: BorderSide(color: surface.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.buttonPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: surface.textPrimary,
                    side: BorderSide(color: surface.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.buttonPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(AiRoutineImportState state) {
    final surface = context.surface;
    final accent = context.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paste Workout Routine',
              style: AppText.body(color: surface.textSecondary),
            ),
            TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: Icon(Icons.content_paste_rounded,
                  size: 16, color: accent.base),
              label: Text('Paste', style: TextStyle(color: accent.base)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surface.surface2,
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: surface.borderSubtle),
          ),
          child: TextField(
            controller: _textController,
            onChanged: (val) {
              ref.read(aiRoutineImportProvider.notifier).setTextInput(val);
            },
            minLines: 8,
            maxLines: 14,
            style: AppText.body(color: surface.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'e.g.\nPush Day A:\nIncline Dumbbell Bench 3x8-10 @ 28kg\nFlat Barbell Bench Press 4x6\nCable Lateral Raises 3x15\nTriceps Pushdowns 3x12',
              hintStyle: AppText.body(color: surface.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    final surface = context.surface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppText.caption(color: surface.textPrimary)
                  .copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
