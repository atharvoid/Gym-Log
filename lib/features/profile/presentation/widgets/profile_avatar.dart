import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// Tappable profile avatar that shows an uploaded profile picture (if one
/// exists) or falls back to the initial-letter avatar. Tapping opens a bottom
/// sheet (Library / Camera / Remove). After picking, the user enters a premium
/// in-app crop screen powered by [crop_your_image].
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

  Future<String?> _compress(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath = p.join(dir.path, _fileName);
    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      outPath,
      quality: 90,
      minWidth: 512,
      minHeight: 512,
    );
    return compressed?.path ?? outPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.selectionClick();
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
    } catch (_) {
      return; // permission denied / cancelled
    }
    if (picked == null || !mounted) return;

    final sourcePath = picked.path;
    final accent = context.accent;

    // Premium in-app crop step — available to all users, zero native deps.
    final croppedPath =
        await Navigator.of(context, rootNavigator: true).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CropScreen(
          sourcePath: sourcePath,
          accentBase: accent.base,
          accentOnAccent: accent.onAccent,
        ),
      ),
    );
    if (croppedPath == null || !mounted) return;

    setState(() => _processing = true);
    try {
      final compressed = await _compress(croppedPath);
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
    final hasImage =
        widget.imagePath != null && widget.imagePath!.isNotEmpty;

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
              if (hasImage)
                _SheetOption(
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
    final hasImage =
        widget.imagePath != null && widget.imagePath!.isNotEmpty;

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

/// Full-screen crop experience using [crop_your_image]. The picked image is
/// shown inside a fixed square viewport; the user pans + pinch-zooms to frame
/// it, then taps 'Use Photo'. The package returns the exact framed square as
/// cropped bytes — deterministic across all device DPRs.
class _CropScreen extends StatefulWidget {
  final String sourcePath;
  final Color accentBase;
  final Color accentOnAccent;
  const _CropScreen({required this.sourcePath, required this.accentBase, required this.accentOnAccent});
  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _controller = CropController();
  Uint8List? _bytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    File(widget.sourcePath).readAsBytes().then((b) {
      if (mounted) setState(() => _bytes = b);
    });
  }

  Future<void> _onCropped(CropResult result) async {
    if (result is! CropSuccess) {
      if (mounted) { setState(() => _saving = false); Navigator.of(context).pop(null); }
      return;
    }
    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await File(outPath).writeAsBytes(result.croppedImage);
    if (mounted) Navigator.of(context).pop(outPath);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Crop Photo', style: AppText.sheetTitle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _saving ? null : () => Navigator.of(context).pop(null),
        ),
      ),
      body: _bytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Crop(
                    image: _bytes!,
                    controller: _controller,
                    aspectRatio: 1,            // square avatar
                    withCircleUi: false,
                    baseColor: Colors.black,
                    maskColor: Colors.black.withValues(alpha: 0.6),
                    cornerDotBuilder: (size, index) =>
                        const DotControl(color: Colors.white),
                    onCropped: _onCropped,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Pinch to zoom · Drag to reposition',
                    style: AppText.caption(color: Colors.white70)),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + media.viewPadding.bottom),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () {
                        setState(() => _saving = true);
                        HapticFeedback.mediumImpact();
                        _controller.crop(); // triggers onCropped
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentBase,
                        foregroundColor: widget.accentOnAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
                        ),
                      ),
                      child: _saving
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.accentOnAccent))
                          : Text('Use Photo', style: AppText.button(color: widget.accentOnAccent)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
