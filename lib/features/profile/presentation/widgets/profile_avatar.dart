import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// Tappable profile avatar that shows an uploaded profile picture (if one
/// exists) or falls back to the initial-letter avatar. A subtle accent-tinted
/// ring frames the avatar, and a camera badge appears in the bottom-right
/// corner when no image is set.
///
/// S11: Profile Picture Upload Feature.
class ProfileAvatar extends StatefulWidget {
  final String displayName;
  final String? imagePath;
  final double size;
  final ValueChanged<String?> onImageChanged;

  const ProfileAvatar({
    super.key,
    required this.displayName,
    this.imagePath,
    this.size = 56,
    required this.onImageChanged,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _processing = false;

  static const _fileName = 'profile_image.jpg';

  Future<String?> _captureAndCompress(XFile picked) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath = p.join(dir.path, _fileName);

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      outPath,
      quality: 85,
      minWidth: 256,
      minHeight: 256,
      inSourceWidth: 256,
      inSourceHeight: 256,
    );
    return compressed?.path ?? outPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.selectionClick();
    setState(() => _processing = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final compressed = await _captureAndCompress(picked);
      if (compressed != null && mounted) {
        HapticFeedback.mediumImpact();
        widget.onImageChanged(compressed);
      }
    } catch (_) {
      // Silently fail — the user can retry.
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _removeImage() async {
    HapticFeedback.lightImpact();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _fileName));
      if (await file.exists()) await file.delete();
    } catch (_) {/* best-effort cleanup */}
    if (mounted) widget.onImageChanged(null);
  }

  void _showOptionsSheet() {
    final hasImage = widget.imagePath != null &&
        widget.imagePath!.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface2,
          borderRadius: AppRadius.sheetTop,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderEmphasis,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Library',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              _SheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (hasImage) _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                isDestructive: true,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _removeImage();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final hasImage = widget.imagePath != null &&
        widget.imagePath!.isNotEmpty;

    return GestureDetector(
      onTap: _processing ? null : _showOptionsSheet,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar with accent-tinted ring.
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
                border: Border.all(
                  color: accent.base.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
                child: _processing
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : hasImage
                        ? Image.file(
                            File(widget.imagePath!),
                            fit: BoxFit.cover,
                            width: widget.size,
                            height: widget.size,
                          )
                        : Container(
                            color: AppColors.surface2,
                            alignment: Alignment.center,
                            child: Text(
                              widget.displayName.isNotEmpty
                                  ? widget.displayName[0].toUpperCase()
                                  : 'A',
                              style: AppText.sheetTitle(
                                      color: AppColors.textSecondary)
                                  .copyWith(fontSize: 20),
                            ),
                          ),
              ),
            ),
            // Camera badge (only when no image is set).
            if (!hasImage && !_processing)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accent.base,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.bgBase,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 10,
                    color: AppColors.onAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(label, style: AppText.body(color: color)),
          ],
        ),
      ),
    );
  }
}
