import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/muscle_glyph.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

/// Dominant muscle token for a template's [RoutineTemplate.focus] — the first
/// token that maps to a real muscle group (skipping qualifiers like "Strength"
/// / "Total Body"), so the glyph is meaningful and not a fallback.
String _dominantMuscle(String focus) {
  final tokens = focus.split(' · ');
  for (final t in tokens) {
    if (MuscleGlyph.groupFor(t) != 'fullbody') return t;
  }
  return tokens.isNotEmpty ? tokens.first : 'fullbody';
}

/// Stable per-muscle tint from the shared violet ramp — IDENTICAL derivation to
/// the saved-routine card, so a chest template and a chest routine read the
/// same.
Color _glyphColor(String muscle) {
  final i = muscle.hashCode.abs() % AppColors.muscleSplitPalette.length;
  return Color.lerp(AppColors.muscleSplitPalette[i], Colors.white, 0.35)!;
}

/// Difficulty filter for the sticky goal chips.
enum _LevelFilter {
  all,
  beginner,
  intermediate,
  advanced;

  String get label => switch (this) {
        _LevelFilter.all => 'All',
        _LevelFilter.beginner => 'Beginner',
        _LevelFilter.intermediate => 'Intermediate',
        _LevelFilter.advanced => 'Advanced',
      };

  bool matches(TemplateLevel l) => switch (this) {
        _LevelFilter.all => true,
        _LevelFilter.beginner => l == TemplateLevel.beginner,
        _LevelFilter.intermediate => l == TemplateLevel.intermediate,
        _LevelFilter.advanced => l == TemplateLevel.advanced,
      };
}

/// A flat content row (featured | section header | card) so the list can be a
/// single virtualized [SliverList] while still driving the staggered entrance
/// by row index.
sealed class _Row {
  const _Row();
}

class _FeaturedRow extends _Row {
  final RoutineTemplate template;
  const _FeaturedRow(this.template);
}

class _HeaderRow extends _Row {
  final String label;
  final int count;
  const _HeaderRow(this.label, this.count);
}

class _CardRow extends _Row {
  final RoutineTemplate template;
  const _CardRow(this.template);
}

/// Explore — a curated catalog of premade routines, importable into the user's
/// library in one tap. Built as a first-impression: an ambient brand glow, a
/// featured spotlight, goal filters, and a choreographed entrance.
class ExploreRoutinesScreen extends ConsumerStatefulWidget {
  const ExploreRoutinesScreen({super.key});

  @override
  ConsumerState<ExploreRoutinesScreen> createState() =>
      _ExploreRoutinesScreenState();
}

class _ExploreRoutinesScreenState extends ConsumerState<ExploreRoutinesScreen>
    with SingleTickerProviderStateMixin {
  /// Templates whose import is in flight (shows the spinner).
  final Set<String> _importing = {};

  /// Templates imported THIS session (optimistic), unioned with the DB-derived
  /// set so "View" shows instantly and survives the rebuild without a flash.
  final Set<String> _imported = {};

  /// name → created routine id, for the "View" action on session imports.
  final Map<String, String> _importedIds = {};

  _LevelFilter _filter = _LevelFilter.all;

  // Drives the one-shot staggered entrance (re-runs when a filter is picked).
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  )..forward();

  static final RoutineTemplate _featured = exploreTemplates.firstWhere(
    (t) => t.featured,
    orElse: () => exploreTemplates.first,
  );

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _setFilter(_LevelFilter f) {
    if (f == _filter) return;
    HapticFeedback.selectionClick();
    setState(() => _filter = f);
    _reveal.forward(from: 0); // re-reveal the new set
  }

  Future<void> _import(RoutineTemplate template) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    // Claim the in-flight lock SYNCHRONOUSLY, before any await — otherwise a
    // double-tap during the count/resolve awaits slips through and imports
    // twice.
    if (_importing.contains(template.name) ||
        _imported.contains(template.name)) {
      return;
    }
    HapticFeedback.selectionClick(); // acknowledge EVERY accepted tap
    setState(() => _importing.add(template.name));

    try {
      final isPremium = ref.read(isPremiumProvider);
      final db = ref.read(databaseProvider);

      final count = await db.routinesDao.countRoutinesForUser(user.id);
      if (!mounted) return;
      if (isAtFreeRoutineLimit(isPremium: isPremium, routineCount: count)) {
        await showPremiumPaywall(context, source: PaywallSource.routineLimit);
        return;
      }

      // Resolve each slot by EXACT canonical name first (audited to exist),
      // falling back to a substring match only for resilience against a
      // differently-versioned library.
      final drafts = <RoutineDraftExercise>[];
      var missed = 0;
      for (final slot in template.slots) {
        final hits = await db.exercisesDao.searchExercises(slot.name);
        Exercise? match;
        for (final e in hits) {
          if (e.name.toLowerCase() == slot.name.toLowerCase()) {
            match = e;
            break;
          }
        }
        match ??= hits.isNotEmpty ? hits.first : null;
        if (match != null) {
          drafts.add(RoutineDraftExercise(
            exerciseId: match.id,
            defaultSets: slot.sets,
            defaultReps: slot.reps,
          ));
        } else {
          missed++;
        }
      }

      if (!mounted) return;
      if (drafts.isEmpty) {
        _snack('Could not match these exercises in your library.');
        return;
      }

      final id = await db.routinesDao.createRoutine(
        userId: user.id,
        name: template.name,
        exercises: drafts,
      );
      if (!mounted) return;

      setState(() {
        _imported.add(template.name);
        _importedIds[template.name] = id;
      });
      HapticFeedback.heavyImpact();
      _snackImported(template.name, id, missed);
    } finally {
      if (mounted) setState(() => _importing.remove(template.name));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content:
            Text(message, style: AppText.meta(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface3,
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// Success snackbar with a one-tap route to the routine just created — a
  /// creation action should lead somewhere, not dead-end.
  void _snackImported(String name, String id, int missed) {
    final msg = missed == 0
        ? '"$name" added to My Routines.'
        : '"$name" added — $missed exercise${missed > 1 ? 's' : ''} not in your library were skipped.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: AppText.meta(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface3,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: AppColors.textPrimary,
          onPressed: () => context.push('/routines/$id'),
        ),
      ));
  }

  void _showPreview(RoutineTemplate t,
      {required bool imported, String? routineId}) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PreviewSheet(
        template: t,
        imported: imported,
        onAdd: () {
          Navigator.of(sheetCtx).pop();
          _import(t);
        },
        onView: routineId == null
            ? null
            : () {
                Navigator.of(sheetCtx).pop();
                context.push('/routines/$routineId');
              },
      ),
    );
  }

  /// Filtered → grouped sections in the curated order. The unfiltered case
  /// reuses the memoized [exploreSections] (minus the featured spotlight).
  List<({String category, List<RoutineTemplate> items})> _sections(
      {required RoutineTemplate? excluded}) {
    final byCategory = <String, List<RoutineTemplate>>{};
    for (final t in exploreTemplates) {
      if (!_filter.matches(t.level)) continue;
      if (identical(t, excluded)) continue;
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }
    return [
      for (final c in exploreCategoryOrder)
        if (byCategory[c] != null) (category: c, items: byCategory[c]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // "Added" state is DERIVED from the reactive routines stream (∪ the session
    // set), so a template whose name already exists shows "View", never a
    // second "Add" — which is what prevents the silent duplicate-import.
    final existing = ref.watch(hydratedRoutinesProvider).valueOrNull ??
        const <HydratedRoutine>[];
    final existingIds = <String, String>{
      for (final r in existing) r.routine.name: r.routine.id,
    };

    final showFeatured = _filter == _LevelFilter.all;
    final sections = _sections(excluded: showFeatured ? _featured : null);

    final rows = <_Row>[
      if (showFeatured) _FeaturedRow(_featured),
      for (final s in sections) ...[
        _HeaderRow(s.category, s.items.length),
        for (final t in s.items) _CardRow(t),
      ],
    ];

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        slivers: [
          // ── Hero: ambient violet aura + collapsing large title ──────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: AppColors.bgBase,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 24, color: AppColors.textPrimary),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () {
                if (context.canPop()) context.pop();
              },
            ),
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsetsDirectional.only(start: 56, bottom: 15),
              expandedTitleScale: 1.6,
              title: _HeroTitle(),
              background: _HeroGlow(),
            ),
          ),

          // ── Subtitle + credibility ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 6, AppSpacing.screenH, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trainer-built programs, ready to train. Import one and '
                    'make it yours.',
                    style: AppText.body(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _CredChip(
                          icon: Icons.list_alt_rounded,
                          label: '${exploreTemplates.length} programs'),
                      const SizedBox(width: AppSpacing.x2),
                      _CredChip(
                          icon: Icons.category_rounded,
                          label: '${exploreCategoryOrder.length} splits'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky goal filters ─────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
                selected: _filter, onSelect: _setFilter),
          ),

          // ── Catalog (featured + sections), staggered entrance ───────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH, 8, AppSpacing.screenH, 24 + bottomInset),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final row = rows[i];
                  final Widget child;
                  switch (row) {
                    case _FeaturedRow(:final template):
                      final imported = _isImported(template, existingIds);
                      final routineId = _routineId(template, existingIds);
                      child = Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.x5),
                        child: _FeaturedCard(
                          template: template,
                          importing: _importing.contains(template.name),
                          imported: imported,
                          onImport: () => _import(template),
                          onView: routineId == null
                              ? null
                              : () => context.push('/routines/$routineId'),
                          onPreview: () => _showPreview(template,
                              imported: imported, routineId: routineId),
                        ),
                      );
                    case _HeaderRow(:final label, :final count):
                      child = _SectionHeader(label: label, count: count);
                    case _CardRow(:final template):
                      final imported = _isImported(template, existingIds);
                      final routineId = _routineId(template, existingIds);
                      child = Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.sectionGap),
                        child: _TemplateCard(
                          template: template,
                          importing: _importing.contains(template.name),
                          imported: imported,
                          onImport: () => _import(template),
                          onView: routineId == null
                              ? null
                              : () => context.push('/routines/$routineId'),
                          onPreview: () => _showPreview(template,
                              imported: imported, routineId: routineId),
                        ),
                      );
                  }
                  return _Reveal(index: i, controller: _reveal, child: child);
                },
                childCount: rows.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isImported(RoutineTemplate t, Map<String, String> existingIds) =>
      _imported.contains(t.name) || existingIds.containsKey(t.name);

  String? _routineId(RoutineTemplate t, Map<String, String> existingIds) =>
      _importedIds[t.name] ?? existingIds[t.name];
}

/// The large "Explore" title that FlexibleSpaceBar scales between the expanded
/// hero and the collapsed app bar.
class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) =>
      Text('Explore', style: AppText.sectionHeading());
}

/// Ambient violet aura behind the hero — gives the AMOLED black depth and brand
/// presence on first open. FlexibleSpaceBar fades it out as the bar collapses.
class _HeroGlow extends StatelessWidget {
  const _HeroGlow();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.35, -0.85),
          radius: 1.15,
          colors: [Color(0x12FFFFFF), Color(0x00000000)],
          stops: [0.0, 0.72],
        ),
      ),
    );
  }
}

class _CredChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CredChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface3,
        borderRadius: AppRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppText.statLabel(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Sticky goal-filter bar. Tapping a chip filters the catalog and re-reveals it.
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final _LevelFilter selected;
  final ValueChanged<_LevelFilter> onSelect;
  _FilterHeaderDelegate({required this.selected, required this.onSelect});

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bgBase,
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 8, AppSpacing.screenH, 10),
        children: [
          for (final f in _LevelFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.x2),
              child: _FilterChip(
                label: f.label,
                selected: f == selected,
                onTap: () => onSelect(f),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterHeaderDelegate old) => old.selected != selected;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.accentPrimary : AppColors.surface3,
        borderRadius: AppRadius.badgeAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: AppText.statLabel(
                  color: selected ? Colors.white : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot fade + rise on first build / filter change. Off-screen rows (index
/// past the first screenful) and reduce-motion render instantly — never blank.
class _Reveal extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;
  const _Reveal(
      {required this.index, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    if (index >= 8 || MediaQuery.disableAnimationsOf(context)) return child;
    final start = (index * 0.07).clamp(0.0, 0.55);
    const span = 0.45;
    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + span).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05), // Translate 5% down
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(label.toUpperCase(),
                style: AppText.columnHeader(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Text('$count', style: AppText.statLabel()),
          ],
        ),
      ),
    );
  }
}

/// The editor's spotlight — a richer, violet-lit hero card the eye lands on
/// first. Same import semantics as a normal card; bigger, glowing, full-width
/// CTA.
class _FeaturedCard extends StatelessWidget {
  final RoutineTemplate template;
  final bool importing;
  final bool imported;
  final VoidCallback onImport;
  final VoidCallback? onView;
  final VoidCallback onPreview;

  const _FeaturedCard({
    required this.template,
    required this.importing,
    required this.imported,
    required this.onImport,
    required this.onView,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final muscle = _dominantMuscle(template.focus);
    final glyphColor = _glyphColor(muscle);
    final a11yLabel = 'Featured. ${template.name}. ${template.levelLabel}, '
        'about ${template.estMinutes} minutes, ${template.slots.length} exercises. '
        '${template.focus}. ${template.description}';

    return Semantics(
      container: true,
      button: true,
      label: a11yLabel,
      hint: 'Opens program preview',
      onTap: onPreview,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.cardAll,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141414), Color(0xFF0B0B0D)],
            ),
            borderRadius: AppRadius.cardAll,
            border: Border.all(
                color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPreview,
              excludeFromSemantics: true,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text('FEATURED',
                                  style: AppText.columnHeader(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: glyphColor.withValues(alpha: 0.16),
                                  borderRadius: AppRadius.thumbnailAll,
                                ),
                                child: MuscleGlyph(
                                    muscle: muscle,
                                    size: 32,
                                    color: glyphColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(template.name,
                                        style: AppText.sectionHeading()),
                                    const SizedBox(height: 3),
                                    Text(template.focus,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.meta()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: AppSpacing.x2,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _LevelPill(
                                  label: template.levelLabel,
                                  color: template.levelColor),
                              _MetaChip(
                                  icon: Icons.schedule_rounded,
                                  label: '~${template.estMinutes} min'),
                              _MetaChip(
                                  icon: Icons.fitness_center_rounded,
                                  label: '${template.slots.length} exercises'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(template.description,
                              style: AppText.body().copyWith(height: 1.45)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ImportPill(
                            importing: importing,
                            imported: imported,
                            onTap: importing
                                ? null
                                : (imported ? (onView ?? () {}) : onImport),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final RoutineTemplate template;
  final bool importing;
  final bool imported;
  final VoidCallback onImport;
  final VoidCallback? onView;
  final VoidCallback onPreview;

  const _TemplateCard({
    required this.template,
    required this.importing,
    required this.imported,
    required this.onImport,
    required this.onView,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final preview = template.slots.take(3).map((s) => s.name).join(', ');
    final extra = template.slots.length - 3;
    final muscle = _dominantMuscle(template.focus);
    final glyphColor = _glyphColor(muscle);

    // One screen-reader node for the whole card (a program), plus the pill's
    // own button node — instead of ~8 disconnected fragments per card.
    final a11yLabel = '${template.name}. ${template.levelLabel}, '
        'about ${template.estMinutes} minutes, ${template.slots.length} exercises. '
        '${template.focus}. ${template.description}';

    return Semantics(
      container: true,
      button: true,
      label: a11yLabel,
      hint: 'Opens program preview',
      onTap: onPreview,
      child: Container(
        decoration: AppCard.decoration(),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPreview,
            excludeFromSemantics: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4, AppSpacing.x4, AppSpacing.x4, AppSpacing.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: glyphColor.withValues(alpha: 0.15),
                                borderRadius: AppRadius.thumbnailAll,
                              ),
                              child: MuscleGlyph(
                                  muscle: muscle, size: 26, color: glyphColor),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(template.name,
                                      style: AppText.cardTitle()),
                                  const SizedBox(height: 3),
                                  Text(template.focus,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.meta()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        // Wrap (not Row) so chips reflow instead of overflowing
                        // on narrow screens / large system text scales.
                        Wrap(
                          spacing: AppSpacing.x2,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _LevelPill(
                                label: template.levelLabel,
                                color: template.levelColor),
                            _MetaChip(
                                icon: Icons.schedule_rounded,
                                label: '~${template.estMinutes} min'),
                            _MetaChip(
                                icon: Icons.fitness_center_rounded,
                                label: '${template.slots.length} exercises'),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Text(template.description,
                            style: AppText.caption().copyWith(height: 1.45)),
                        const Padding(
                          padding: EdgeInsets.only(top: 13),
                          child: Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.borderSubtle),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              '$preview${extra > 0 ? '  +$extra' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption(
                                  color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        _ImportPill(
                          importing: importing,
                          imported: imported,
                          onTap: importing
                              ? null
                              : (imported ? (onView ?? () {}) : onImport),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final String label;
  final Color color;
  const _LevelPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: AppText.badge(color: color)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppText.meta()),
      ],
    );
  }
}

/// Compact in-card CTA: Add → (spinner) → View. On-system radius (NOT a pill),
/// a 48dp tap target, and a reduce-motion-gated swap animation so a successful
/// import resolves with a satisfying check instead of snapping. Wrap in an
/// [Expanded] to stretch it full-width (the featured hero does this).
class _ImportPill extends StatelessWidget {
  final bool importing;
  final bool imported;
  final VoidCallback? onTap;

  const _ImportPill({
    required this.importing,
    required this.imported,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fg = imported ? AppColors.success : Colors.white;

    final Widget child = importing
        ? const SizedBox(
            key: ValueKey('spin'),
            width: 16,
            height: 16,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            key: ValueKey(imported),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(imported ? Icons.check_rounded : Icons.download_rounded,
                  size: 16, color: fg),
              const SizedBox(width: 6),
              Text(imported ? 'View' : 'Add',
                  style: AppText.statLabel(color: fg)),
            ],
          );

    return Semantics(
      button: true,
      enabled: !importing,
      label: importing
          ? 'Adding routine'
          : imported
              ? 'Added — view routine'
              : 'Add this routine',
      excludeSemantics: true,
      child: Material(
        color: imported
            ? AppColors.success.withValues(alpha: 0.14)
            : AppColors.accentPrimary,
        borderRadius: AppRadius.buttonSecondaryAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 86),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: reduceMotion ? 0 : 200),
              transitionBuilder: (c, anim) => FadeTransition(
                  opacity: anim, child: ScaleTransition(scale: anim, child: c)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-template preview — every slot (name · sets×reps) so a user can evaluate
/// a program before committing. Primary action mirrors the card: Add (or View
/// if it's already in the library).
class _PreviewSheet extends StatelessWidget {
  final RoutineTemplate template;
  final bool imported;
  final VoidCallback onAdd;
  final VoidCallback? onView;

  const _PreviewSheet({
    required this.template,
    required this.imported,
    required this.onAdd,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final muscle = _dominantMuscle(template.focus);
    final glyphColor = _glyphColor(muscle);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface2, AppColors.bgBase],
          ),
          borderRadius: AppRadius.sheetTop,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderEmphasis,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5, AppSpacing.x5, AppSpacing.x5, AppSpacing.x4),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: glyphColor.withValues(alpha: 0.15),
                          borderRadius: AppRadius.thumbnailAll,
                        ),
                        child: MuscleGlyph(
                            muscle: muscle, size: 28, color: glyphColor),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(template.name,
                                style: AppText.sectionHeading()),
                            const SizedBox(height: 3),
                            Text(template.focus, style: AppText.meta()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Wrap(
                    spacing: AppSpacing.x2,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _LevelPill(
                          label: template.levelLabel,
                          color: template.levelColor),
                      _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: '~${template.estMinutes} min'),
                      _MetaChip(
                          icon: Icons.fitness_center_rounded,
                          label: '${template.slots.length} exercises'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text(template.description,
                      style: AppText.body().copyWith(height: 1.45)),
                  const SizedBox(height: AppSpacing.x5),
                  Text('EXERCISES',
                      style: AppText.columnHeader(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.x2),
                  for (var i = 0; i < template.slots.length; i++)
                    _PreviewSlotRow(index: i + 1, slot: template.slots[i]),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5, 0, AppSpacing.x5, AppSpacing.x3),
                child: PrimaryButton(
                  label:
                      imported ? 'View in My Routines' : 'Add to My Routines',
                  icon: imported ? Icons.check_rounded : Icons.download_rounded,
                  onPressed: imported ? onView : onAdd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSlotRow extends StatelessWidget {
  final int index;
  final TemplateSlot slot;
  const _PreviewSlotRow({required this.index, required this.slot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$index', style: AppText.statLabel()),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(slot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowLabel()),
          ),
          const SizedBox(width: AppSpacing.x2),
          Text('${slot.sets} × ${slot.reps}',
              style: AppText.statLabel(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
