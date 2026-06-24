import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

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

  /// Crop the picked image with a premium-feeling square cropper.
  /// Accent-tinted toolbar, smooth animations, 1:1 lock.
  Future<File?> _cropImage(String sourcePath, Color accentBase) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: accentBase,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: accentBase,
          lockAspectRatio: true,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          hideBottomControls: false,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioPresets: [CropAspectRatioPreset.square],
          aspectRatioLockEnabled: true,
          aspectRatioLockDimensionSwapEnabled: false,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    return cropped == null ? null : File(cropped.path);
  }

  Future<String?> _compress(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath = p.join(dir.path, _fileName);

    final compressed = await FlutterImageCompress.compressAndGetFile(
      source.path,
      outPath,
      quality: 90,
      minWidth: 256,
      minHeight: 256,
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked == null) return;

      // Premium crop step — available to all users.
      final accent = context.accent;
      final croppedFile = await _cropImage(picked.path, accent.base);
      if (croppedFile == null) return; // user cancelled crop

      final compressed = await _compress(croppedFile);
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
    final surface = context.surface;
    final hasImage = widget.imagePath != null &&
        widget.imagePath!.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: surface.surface2,
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
                  color: surface.borderEmphasis,
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
    final surface = context.surface;
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
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: surface.textSecondary,
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
                            color: surface.surface2,
                            alignment: Alignment.center,
                            child: Text(
                              widget.displayName.isNotEmpty
                                  ? widget.displayName[0].toUpperCase()
                                  : 'A',
                              style: AppText.sheetTitle(
                                      color: surface.textSecondary)
                                  .copyWith(fontSize: 20),
                            ),
                          ),
              ),
            ),
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
                      color: surface.bgBase,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 10,
                    color: accent.onAccent,
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
    final surface = context.surface;
    final color = isDestructive ? AppColors.error : surface.textPrimary;
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