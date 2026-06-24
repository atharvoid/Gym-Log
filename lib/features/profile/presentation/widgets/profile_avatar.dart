import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// A tappable profile avatar that shows an uploaded profile picture (if one
/// exists) or falls back to the initial-letter avatar.
///
/// S11: Profile Picture Upload Feature.
///
/// Requires the following pubspec dependencies:
///   image_picker: ^1.1.2
///   image_cropper: ^8.0.2
///   flutter_image_compress: ^2.3.0
///
/// Add them with: flutter pub add image_picker image_cropper flutter_image_compress
///
/// Also add to Android AndroidManifest.xml inside <activity>:
///   <activity
///     android:name="com.yalantis.ucrop.UCropActivity"
///     android:screenOrientation="portrait"
///     android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
class ProfileAvatar extends StatefulWidget {
  final String displayName;
  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.displayName,
    this.imagePath,
    required this.onImageChanged,
    this.size = 56,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _processing = false;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _localPath = widget.imagePath;
  }

  Future<void> _showOptionsSheet() {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
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
              Text('Profile Photo', style: AppText.cardTitle()),
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
              if (_localPath != null)
                _SheetOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove Photo',
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _removeImage();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      // Crop to 1:1 square.
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppColors.bgBase,
            toolbarWidgetColor: AppColors.textPrimary,
            backgroundColor: AppColors.bgBase,
            activeControlsWidgetColor: context.accent.base,
            cropFrameColor: context.accent.base,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            aspectRatioPickerOptionHidden: true,
          ),
        ],
      );
      if (cropped == null) return;

      // Compress to 256x256 and save to app documents directory.
      final dir = await getApplicationDocumentsDirectory();
      final targetPath =
          '${dir.path}/profile_image.jpg';

      await FlutterImageCompress.compressAndGetFile(
        cropped.path,
        targetPath,
        quality: 88,
        minWidth: 256,
        minHeight: 256,
      );

      if (!mounted) return;
      setState(() => _localPath = targetPath);
      widget.onImageChanged(targetPath);
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail — user can retry. No crash on permission denial.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Could not save photo. Check camera/photo permissions.',
            style: AppText.body(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.surface3,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _removeImage() {
    HapticFeedback.lightImpact();
    setState(() => _localPath = null);
    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final hasImage = _localPath != null && File(_localPath!).existsSync();

    return Semantics(
      button: true,
      label: hasImage
          ? 'Profile photo. Double tap to change.'
          : 'Profile photo placeholder. Double tap to upload a photo.',
      child: GestureDetector(
        onTap: _processing ? null : _showOptionsSheet,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
            border: Border.all(
              color: accent.base.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Avatar content
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
                child: hasImage
                    ? Image.file(
                        File(_localPath!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
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
              // Camera badge (bottom-right) when no image is set
              if (!hasImage && !_processing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.base,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.bgBase, width: 1.5),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 10,
                      color: accent.onAccent,
                    ),
                  ),
                ),
              // Processing overlay
              if (_processing)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppRadius.buttonPrimary),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? AppColors.error
                    : accent.light,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
