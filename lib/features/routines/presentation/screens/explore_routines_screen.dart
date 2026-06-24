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
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/muscle_glyph.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

String _dominantMuscle(String focus) {
  final tokens = focus.split(' · ');
  for (final t in tokens) {
    if (MuscleGlyph.groupFor(t) != 'fullbody') return t;
  }
  return tokens.isNotEmpty ? tokens.first : 'fullbody';
}

Color _glyphColor(String muscle, List<Color> ramp) {
  final i = muscle.hashCode.abs() % ramp.length;
  return Color.lerp(ramp[i], Colors.white, 0.35)!;
}

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

class ExploreRoutinesScreen extends ConsumerStatefulWidget {
  const ExploreRoutinesScreen({super.key});

  @override
  ConsumerState<ExploreRoutinesScreen> createState() =>
      _ExploreRoutinesScreenState();
}

class _ExploreRoutinesScreenState extends ConsumerState<ExploreRoutinesScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _importing = {};
  final Set<String> _imported = {};
  final Map<String, String> _importedIds = {};
  _LevelFilter _filter = _LevelFilter.all;

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
    _reveal.forward(from: 0);
  }

  Future<void> _import(RoutineTemplate template) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    if (_importing.contains(template.name) ||
        _imported.contains(template.name)) {
      return;
    }
    HapticFeedback.selectionClick();
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
    final ramp = context.accent.muscleSplitRamp;
    final surface = context.surface;

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
      backgroundColor: surface.bgBase,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: surface.bgBase,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              icon: Icon(Icons.arrow_back_rounded,
                  size: 24, color: surface.textPrimary),
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
                    style: AppText.body(color: surface.textSecondary),
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

          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
                selected: _filter, onSelect: _setFilter),
          ),

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
                          ramp: ramp,
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
                          ramp: ramp,
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

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) =>
      Text('Explore', style: AppText.sectionHeading(
          color: context.surface.textPrimary,
          shadows: AppText.depthFor(context)));
}

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
    final surface = context.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surface.surface3,
        borderRadius: AppRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: surface.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppText.statLabel(color: surface.textSecondary)),
        ],
      ),
    );
  }
}

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
      color: context.surface.bgBase,
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
    final accent = context.accent;
    final surface = context.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? accent.base : surface.surface3,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: AppText.statLabel(
                  color: selected ? accent.onAccent : surface.textSecondary,
                  shadows: selected ? TextDepth.onAccentHalo(context.accent.palette) : null),
            ),
          ),
        ),
      ),
    );
  }
}

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
          begin: const Offset(0, 0.05),
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
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(label.toUpperCase(),
                style: AppText.columnHeader(color: surface.textSecondary)),
            const SizedBox(width: 8),
            Text('$count', style: AppText.statLabel(color: surface.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final RoutineTemplate template;
  final List<Color> ramp;
  final bool importing;
  final bool imported;
  final VoidCallback onImport;
  final VoidCallback? onView;
  final VoidCallback onPreview;

  const _FeaturedCard({
    required this.template,
    required this.ramp,
    required this.importing,
    required this.imported,
    required this.onImport,
    required this.onView,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    final muscle = _dominantMuscle(template.focus);
    final glyphColor = _glyphColor(muscle, ramp);
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
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardAll,
          boxShadow: [
            BoxShadow(
              color: accent.glow,
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: surface.isLight
                  ? [surface.surface2, surface.bgSurface]
                  : [AppColors.surface2, const Color(0xFF0B0B0D)],
            ),
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: surface.borderSubtle),
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
                              Icon(Icons.auto_awesome_rounded,
                                  size: 13, color: surface.textSecondary),
                              const SizedBox(width: 6),
                              Text('FEATURED',
                                  style: AppText.columnHeader(
                                      color: surface.textSecondary)),
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
                                        style: AppText.sectionHeading(
                                            color: surface.textPrimary,
                                            shadows: AppText.depthFor(context))),
                                    const SizedBox(height: 3),
                                    Text(template.focus,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.meta(color: surface.textSecondary)),
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
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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
  final List<Color> ramp;
  final bool importing;
  final bool imported;
  final VoidCallback onImport;
  final VoidCallback? onView;
  final VoidCallback onPreview;

  const _TemplateCard({
    required this.template,
    required this.ramp,
    required this.importing,
    required this.imported,
    required this.onImport,
    required this.onView,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    final preview = template.slots.take(3).map((s) => s.name).join(', ');
    final extra = template.slots.length - 3;
    final muscle = _dominantMuscle(template.focus);
    final glyphColor = _glyphColor(muscle, ramp);

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
        decoration: BoxDecoration(
          color: surface.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: surface.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: accent.glow,
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                                      style: AppText.cardTitle(
                                          color: surface.textPrimary,
                                          shadows: AppText.depthFor(context))),
                                  const SizedBox(height: 3),
                                  Text(template.focus,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.meta(color: surface.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x3),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 13),
                          child: Divider(
                              height: 1,
                              thickness: 1,
                              color: surface.borderSubtle),
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
                                  color: surface.textTertiary),
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
    final surface = context.surface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: surface.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppText.meta(color: surface.textSecondary)),
      ],
    );
  }
}

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
    final surface = context.surface;
    final fg = imported ? AppColors.success : surface.textPrimary;

    final Widget child = importing
        ? SizedBox(
            key: const ValueKey('spin'),
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: surface.textPrimary),
          )
        : Row(
            key: ValueKey(imported),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(imported ? Icons.check_rounded : Icons.download_rounded,
                  size: 16, color: fg),
              const SizedBox(width: 6),
              Text(imported ? 'View' : 'Add',
                  style: AppText.statLabel(
                      color: fg,
                      shadows: !imported ? TextDepth.onAccentHalo(context.accent.palette) : null)),
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
            : context.accent.base,
        borderRadius: BorderRadius.circular(14),
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
    final surface = context.surface;
    final muscle = _dominantMuscle(template.focus);
    final ramp = context.accent.muscleSplitRamp;
    final glyphColor = _glyphColor(muscle, ramp);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: surface.isLight
                ? [surface.surface2, surface.bgBase]
                : [AppColors.surface2, AppColors.bgBase],
          ),
          borderRadius: AppRadius.sheetTop,
          border: Border(top: BorderSide(color: surface.borderSubtle)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: surface.borderEmphasis,
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
                                style: AppText.sectionHeading(
                                    color: surface.textPrimary,
                                    shadows: AppText.depthFor(context))),
                            const SizedBox(height: 3),
                            Text(template.focus, style: AppText.meta(color: surface.textSecondary)),
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
                      style: AppText.body(color: surface.textSecondary).copyWith(height: 1.45)),
                  const SizedBox(height: AppSpacing.x5),
                  Text('EXERCISES',
                      style: AppText.columnHeader(
                          color: surface.textSecondary)),
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
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$index', style: AppText.statLabel(color: surface.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(slot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowLabel(color: surface.textPrimary)),
          ),
          const SizedBox(width: AppSpacing.x2),
          Text('${slot.sets} × ${slot.reps}',
              style: AppText.statLabel(color: surface.textSecondary)),
        ],
      ),
    );
  }
}
