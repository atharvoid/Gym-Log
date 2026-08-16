// [routine_muscle_glyph.dart]
// A card-sized muscle preview for a SINGLE routine.
//
// WHY NOT MuscleMap
// MuscleMap renders layered SVG body parts, front and back, plus a legend. It
// is the right tool on a detail screen and far too heavy for a list cell --
// and Explore only ever showed one, for the whole program, which meant every
// muscle highlighted and the map communicated nothing.
//
// This glyph answers one question at a glance: what does THIS routine train?
// Six zones, drawn with a CustomPainter, no new assets, ~44x56 logical px.
//
// Group names are the String keys used by `kGroupToParts` in
// core/exercises/body_map.dart -- 'Chest', 'Quadriceps', 'Full Body', and so
// on -- so the output of `workedGroupsFor()` can be passed straight in.

import 'package:flutter/material.dart';

import 'package:gymlog/core/theme/app_colors.dart';

/// The six coarse regions this glyph can highlight.
enum RoutineGlyphZone { shoulders, chest, back, arms, core, legs }

/// Sentinel group name from body_map.dart meaning "highlight everything".
const String kFullBodyGroup = 'Full Body';

/// Maps body_map.dart parent group names onto glyph zones.
const Map<String, RoutineGlyphZone> kGroupToGlyphZone = {
  'Chest': RoutineGlyphZone.chest,
  'Back': RoutineGlyphZone.back,
  'Shoulders': RoutineGlyphZone.shoulders,
  'Biceps': RoutineGlyphZone.arms,
  'Triceps': RoutineGlyphZone.arms,
  'Forearms': RoutineGlyphZone.arms,
  'Core': RoutineGlyphZone.core,
  'Quadriceps': RoutineGlyphZone.legs,
  'Hamstrings': RoutineGlyphZone.legs,
  'Glutes': RoutineGlyphZone.legs,
  'Calves': RoutineGlyphZone.legs,
  'Adductors': RoutineGlyphZone.legs,
  'Abductors': RoutineGlyphZone.legs,
  'Hip Flexors': RoutineGlyphZone.legs,
};

/// Resolves parent group names to glyph zones. Unknown groups (including
/// 'Neck' and 'Other') are dropped rather than throwing, matching the
/// forgiving behaviour of `partsForGroups`.
Set<RoutineGlyphZone> routineGlyphZonesFor(Set<String> groups) {
  if (groups.contains(kFullBodyGroup)) {
    return RoutineGlyphZone.values.toSet();
  }
  final zones = <RoutineGlyphZone>{};
  for (final group in groups) {
    final zone = kGroupToGlyphZone[group];
    if (zone != null) zones.add(zone);
  }
  return zones;
}

/// A short spoken description for screen readers, e.g. "Trains chest, arms".
String routineGlyphSemanticLabel(Set<String> primaryGroups) {
  if (primaryGroups.isEmpty) return 'No muscle data for this routine';
  if (primaryGroups.contains(kFullBodyGroup)) return 'Trains the full body';
  final sorted = primaryGroups.toList()..sort();
  return 'Trains ${sorted.join(', ').toLowerCase()}';
}

/// Compact body glyph showing which regions a routine trains.
///
/// [primaryGroups] paint at full strength, [secondaryGroups] at 40%, and
/// everything else stays as a neutral silhouette.
class RoutineMuscleGlyph extends StatelessWidget {
  const RoutineMuscleGlyph({
    super.key,
    required this.primaryGroups,
    this.secondaryGroups = const <String>{},
    this.size = const Size(44, 56),
    this.highlight,
  });

  final Set<String> primaryGroups;
  final Set<String> secondaryGroups;
  final Size size;

  /// Defaults to the brand accent fallback. Call sites with access to the
  /// reactive theme should pass the live accent instead.
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final primaryZones = routineGlyphZonesFor(primaryGroups);
    final secondaryZones =
        routineGlyphZonesFor(secondaryGroups).difference(primaryZones);

    return Semantics(
      label: routineGlyphSemanticLabel(primaryGroups),
      excludeSemantics: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: size,
          painter: _RoutineMuscleGlyphPainter(
            primaryZones: primaryZones,
            secondaryZones: secondaryZones,
            highlight: highlight ?? AppColors.accentPrimary,
            inactive: surface.borderDefault,
            outline: surface.borderSubtle,
          ),
        ),
      ),
    );
  }
}

/// Design-space geometry. All rects are expressed on a 44x56 canvas and
/// scaled to whatever size the widget is given, so the glyph stays crisp at
/// any density without a second set of magic numbers.
const double _designWidth = 44;
const double _designHeight = 56;
const Radius _zoneRadius = Radius.circular(2);

const Map<RoutineGlyphZone, List<Rect>> _zoneGeometry = {
  RoutineGlyphZone.shoulders: [
    Rect.fromLTWH(9, 13.5, 10, 5),
    Rect.fromLTWH(25, 13.5, 10, 5),
  ],
  RoutineGlyphZone.chest: [
    Rect.fromLTWH(13.75, 19, 16.5, 9),
  ],
  // Rendered as lat rails down the outside of the torso -- the clearest way to
  // say "back" on a front-facing silhouette.
  RoutineGlyphZone.back: [
    Rect.fromLTWH(11, 19, 2.5, 20),
    Rect.fromLTWH(30.5, 19, 2.5, 20),
  ],
  RoutineGlyphZone.arms: [
    Rect.fromLTWH(5.5, 20, 4.5, 17),
    Rect.fromLTWH(34, 20, 4.5, 17),
  ],
  RoutineGlyphZone.core: [
    Rect.fromLTWH(13.75, 29, 16.5, 10),
  ],
  RoutineGlyphZone.legs: [
    Rect.fromLTWH(13.75, 40, 7, 14),
    Rect.fromLTWH(23.25, 40, 7, 14),
  ],
};

const Offset _headCenter = Offset(22, 6);
const double _headRadius = 4.5;

/// Secondary muscles read at 40% -- present, clearly subordinate.
const int _secondaryAlpha = 0x66;

class _RoutineMuscleGlyphPainter extends CustomPainter {
  const _RoutineMuscleGlyphPainter({
    required this.primaryZones,
    required this.secondaryZones,
    required this.highlight,
    required this.inactive,
    required this.outline,
  });

  final Set<RoutineGlyphZone> primaryZones;
  final Set<RoutineGlyphZone> secondaryZones;
  final Color highlight;
  final Color inactive;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _designWidth;
    final scaleY = size.height / _designHeight;

    final paint = Paint()..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(_headCenter.dx * scaleX, _headCenter.dy * scaleY),
      _headRadius * ((scaleX + scaleY) / 2),
      paint..color = outline,
    );

    for (final zone in RoutineGlyphZone.values) {
      final Color color;
      if (primaryZones.contains(zone)) {
        color = highlight;
      } else if (secondaryZones.contains(zone)) {
        color = highlight.withAlpha(_secondaryAlpha);
      } else {
        color = inactive;
      }

      paint.color = color;

      for (final rect in _zoneGeometry[zone]!) {
        final scaled = Rect.fromLTWH(
          rect.left * scaleX,
          rect.top * scaleY,
          rect.width * scaleX,
          rect.height * scaleY,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(scaled, _zoneRadius),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RoutineMuscleGlyphPainter oldDelegate) {
    return highlight != oldDelegate.highlight ||
        inactive != oldDelegate.inactive ||
        outline != oldDelegate.outline ||
        !setEquals(primaryZones, oldDelegate.primaryZones) ||
        !setEquals(secondaryZones, oldDelegate.secondaryZones);
  }
}
