import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// [theme_svg.dart]
/// Theme-reactive SVG renderer. Loads an SVG asset once, caches the raw
/// string, then at render time replaces literal placeholder hex codes with
/// the live accent palette values.
///
/// SVG authoring convention: use these literal placeholders in the SVG source:
///   #ACCENT_BASE  → replaced with accent.base hex
///   #ACCENT_LIGHT → replaced with accent.light hex
///   #ACCENT_DARK   → replaced with accent.dark hex
///   #ACCENT_MUTED → replaced with accent.muted hex
///
/// Usage:
///   ThemeSvg(assetPath: 'assets/svgs/routines/chest.svg', size: 44)
///
/// The widget is a StatefulWidget so it can load asynchronously and cache.
/// The static [_cache] map survives widget rebuilds and disposals.
class ThemeSvg extends StatefulWidget {
  final String assetPath;
  final double size;

  const ThemeSvg({
    super.key,
    required this.assetPath,
    this.size = 48,
  });

  @override
  State<ThemeSvg> createState() => _ThemeSvgState();
}

class _ThemeSvgState extends State<ThemeSvg> {
  /// Process-wide cache: asset path → raw SVG string. Survives widget
  /// disposal so re-mounting a ThemeSvg with the same asset is instant.
  static final Map<String, String> _cache = {};

  String? _svgString;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    if (_cache.containsKey(widget.assetPath)) {
      _svgString = _cache[widget.assetPath];
      if (mounted) setState(() => _loaded = true);
      return;
    }
    final str = await rootBundle.loadString(widget.assetPath);
    _cache[widget.assetPath] = str;
    _svgString = str;
    if (mounted) setState(() => _loaded = true);
  }

  /// Converts a [Color] to a `#RRGGBB` hex string (uppercase, no alpha).
  static String _hex(Color c) {
    final a = c.toARGB32();
    return '#${(a & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _svgString == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    final accent = context.accent;
    final themed = _svgString!
        .replaceAll('#ACCENT_BASE', _hex(accent.base))
        .replaceAll('#ACCENT_LIGHT', _hex(accent.light))
        .replaceAll('#ACCENT_DARK', _hex(accent.dark))
        .replaceAll('#ACCENT_MUTED', _hex(accent.muted));
    return SvgPicture.string(
      themed,
      width: widget.size,
      height: widget.size,
    );
  }
}
