// Static, synthetic concept renders. No app route or production behavior uses
// these widgets. Selection/persistence/start behavior waits for the owner's pick.
import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/bottom_nav_bar.dart';
import 'session_2_fixtures.dart';

enum LaunchOption { chosen, sequence, chooser }

class LaunchConcept extends StatelessWidget {
  const LaunchConcept(
      {super.key,
      required this.option,
      required this.screen,
      required this.fixtureState});
  final LaunchOption option;
  final String screen;
  final LaunchState fixtureState;

  bool get _isHome => screen == 'home';
  bool get _hasPlan =>
      fixtureState != LaunchState.empty &&
      fixtureState != LaunchState.noRoutine &&
      fixtureState != LaunchState.error;
  int get _selected => fixtureState == LaunchState.lowData
      ? 4
      : option == LaunchOption.sequence
          ? 2
          : 0;

  @override
  Widget build(BuildContext context) {
    final dock = option == LaunchOption.chooser && _hasPlan;
    return Scaffold(
      backgroundColor: context.surface.bgBase,
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: AppSpacing.x6),
                    if (fixtureState == LaunchState.error)
                      _error(context)
                    else if (!_hasPlan)
                      _empty(context)
                    else if (_isHome)
                      _home(context)
                    else
                      _library(context),
                    const SizedBox(height: AppSpacing.x6),
                  ]))),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        if (dock)
          Container(
              color: context.surface.bgSurface,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4, AppSpacing.x3, AppSpacing.x4, AppSpacing.x3),
              child: _primary(context, 'Start ${samplePlans[_selected].name}')),
        BottomNavBar(currentIndex: _isHome ? 0 : 1, onTap: (_) {}),
      ]),
    );
  }

  Widget _header(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_isHome ? 'Train' : 'Routines',
            style: AppText.screenTitle(color: context.surface.textPrimary)),
        if (!_isHome) ...[
          const SizedBox(height: AppSpacing.x1),
          Text(
              fixtureState == LaunchState.error
                  ? 'Library unavailable'
                  : '${sampleRoutines(fixtureState).length} saved routines',
              style: AppText.body(color: context.surface.textSecondary)),
          Wrap(spacing: AppSpacing.x4, children: [
            _link(context, 'New routine', icon: Icons.add_rounded),
            _link(context, 'Explore', icon: Icons.explore_outlined)
          ]),
        ] else if (fixtureState == LaunchState.inactive) ...[
          const SizedBox(height: AppSpacing.x2),
          Text('Last workout: 14 Sep · 18 days ago',
              style: AppText.body(color: context.surface.textSecondary)),
        ],
      ]);

  Widget _home(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (option == LaunchOption.chosen) ...[
          _kicker(context, 'YOUR CHOICE'),
          _routineHeading(context, _selected),
          _link(context, 'Change routine', icon: Icons.swap_horiz_rounded),
          _lastSet(context, _selected),
          const SizedBox(height: AppSpacing.x4),
          _primary(context, 'Start ${samplePlans[_selected].name}'),
        ] else if (option == LaunchOption.sequence &&
            fixtureState != LaunchState.lowData) ...[
          _kicker(context, 'SUGGESTED FROM YOUR PROGRAM'),
          Text('Push / Pull / Legs',
              style: AppText.titleLarge(color: context.surface.textPrimary)),
          const SizedBox(height: AppSpacing.x3),
          _sequence(context),
          const SizedBox(height: AppSpacing.x4),
          _routineHeading(context, _selected),
          Text(
              'Legs A follows Pull A in your saved order.\nLast Pull A: ${fixtureState == LaunchState.inactive ? '14 Sep' : '30 Sep'}.',
              style: AppText.body(color: context.surface.textSecondary)),
          const SizedBox(height: AppSpacing.x3),
          _primary(context, 'Start Legs A'),
          _link(context, 'Choose something else',
              icon: Icons.swap_horiz_rounded),
          _lastSet(context, _selected),
        ] else if (option == LaunchOption.chooser) ...[
          Text('What will you train?',
              style: AppText.titleLarge(color: context.surface.textPrimary)),
          const SizedBox(height: AppSpacing.x2),
          Text('Choose a routine for this session.',
              style: AppText.body(color: context.surface.textSecondary)),
          const SizedBox(height: AppSpacing.x4),
          if (fixtureState != LaunchState.lowData)
            _kicker(context, 'PUSH / PULL / LEGS'),
          for (final i in fixtureState == LaunchState.lowData ? [4] : [0, 1, 2])
            _choiceRow(context, i),
          _link(context, 'All routines', icon: Icons.chevron_right_rounded),
          const SizedBox(height: AppSpacing.x2),
          _lastSet(context, _selected),
        ] else ...[
          _kicker(context, 'YOUR ONLY SAVED ROUTINE'),
          _routineHeading(context, 4),
          _lastSet(context, 4),
          const SizedBox(height: AppSpacing.x4),
          _primary(context, 'Start Outdoor walk'),
        ],
        const SizedBox(height: AppSpacing.x6),
        _utilities(context),
        const SizedBox(height: AppSpacing.x4),
        _weekly(context),
        const SizedBox(height: AppSpacing.x6),
        _recent(context),
      ]);

  Widget _library(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (fixtureState == LaunchState.lowData) ...[
          _routineHeading(context, 4),
          _lastSet(context, 4),
          if (option != LaunchOption.chooser) ...[
            const SizedBox(height: AppSpacing.x4),
            _primary(context, 'Start Outdoor walk'),
          ],
        ] else if (option == LaunchOption.chosen) ...[
          _panel(
              context,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _kicker(context, 'CHOSEN FOR HOME'),
                _routineHeading(context, 0),
                const SizedBox(height: AppSpacing.x3),
                _primary(context, 'Start Push A'),
                _link(context, 'Change Home choice',
                    icon: Icons.push_pin_outlined),
              ])),
          const SizedBox(height: AppSpacing.x6),
          _programHeading(context),
          for (final i in [0, 1, 2]) _routineRow(context, i, selected: i == 0),
          const SizedBox(height: AppSpacing.x4),
          _kicker(context, 'STANDALONE ROUTINES'),
          for (final i in [3, 4]) _routineRow(context, i),
        ] else if (option == LaunchOption.sequence) ...[
          _programHeading(context),
          _panel(
              context,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _kicker(context, 'NEXT IN SAVED ORDER'),
                _routineHeading(context, 2),
                Text('Follows your last logged Pull A.',
                    style: AppText.body(color: context.surface.textSecondary)),
                const SizedBox(height: AppSpacing.x3),
                _primary(context, 'Start Legs A'),
              ])),
          const SizedBox(height: AppSpacing.x4),
          _sequence(context),
          const SizedBox(height: AppSpacing.x3),
          for (final i in [0, 1, 2]) _routineRow(context, i),
          const SizedBox(height: AppSpacing.x6),
          _kicker(context, 'STANDALONE ROUTINES'),
          for (final i in [3, 4]) _routineRow(context, i),
        ] else ...[
          _programHeading(context, folder: true),
          for (final i in [0, 1, 2]) _choiceRow(context, i),
          const SizedBox(height: AppSpacing.x6),
          _kicker(context, 'STANDALONE ROUTINES'),
          for (final i in [3, 4]) _choiceRow(context, i),
          const SizedBox(height: AppSpacing.x4),
          _lastSet(context, _selected),
        ],
      ]);

  Widget _routineHeading(BuildContext context, int i) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(samplePlans[i].name,
            style: AppText.screenTitle(color: context.surface.textPrimary)),
        const SizedBox(height: AppSpacing.x2),
        if (i < 3 && option != LaunchOption.sequence)
          Text('Push / Pull / Legs',
              style: AppText.body(color: context.surface.textSecondary)),
        Text(
            '${samplePlans[i].exercises.length} ${i == 4 ? 'exercise' : 'exercises'}${i == 4 ? '' : ' · ${samplePlans[i].exercises.length * 3} planned sets'}',
            style: AppText.body(color: context.surface.textSecondary)),
        if (samplePlans[i].focus.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x2),
          Text(samplePlans[i].focus.join(' · '),
              style: AppText.body(color: context.surface.textPrimary)),
        ],
      ]);

  Widget _lastSet(BuildContext context, int i) {
    final missing = fixtureState == LaunchState.lowData || i > 2;
    final date = fixtureState == LaunchState.inactive
        ? (i == 0
            ? '12 Sep'
            : i == 1
                ? '14 Sep'
                : '9 Sep')
        : i == 0
            ? '28 Sep'
            : i == 1
                ? '30 Sep'
                : '26 Sep';
    final exercise = i == 0
        ? 'Bench Press'
        : i == 1
            ? 'Lat Pulldown'
            : 'Squat';
    final value = i == 0
        ? '60 kg × 8'
        : i == 1
            ? '50 kg × 10'
            : '80 kg × 5';
    return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.x4),
        child: _panel(
            context,
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  missing
                      ? 'No sessions logged for this routine'
                      : 'Last ${samplePlans[i].name} · $date',
                  style: AppText.meta(color: context.surface.textSecondary)),
              const SizedBox(height: AppSpacing.x2),
              Text(
                  missing
                      ? 'Start from the saved plan. There is no previous session to compare.'
                      : exercise,
                  style: AppText.body(color: context.surface.textPrimary)),
              if (!missing) ...[
                const SizedBox(height: AppSpacing.x1),
                Text('$value · logged set',
                    style:
                        AppText.sheetTitle(color: context.surface.textPrimary)
                            .copyWith(fontFeatures: kTabular)),
              ],
            ])));
  }

  Widget _routineRow(BuildContext context, int i, {bool selected = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(samplePlans[i].name,
                      style: AppText.sheetTitle(
                          color: context.surface.textPrimary))),
              if (selected)
                Icon(Icons.push_pin_outlined,
                    size: 20, color: context.accent.base)
            ]),
            const SizedBox(height: AppSpacing.x1),
            Text(
                '${samplePlans[i].exercises.length} ${i == 4 ? 'exercise' : 'exercises'} · ${i > 2 ? 'No sessions yet' : 'Last ${fixtureState == LaunchState.inactive ? (i == 0 ? '12 Sep' : i == 1 ? '14 Sep' : '9 Sep') : i == 0 ? '28 Sep' : i == 1 ? '30 Sep' : '26 Sep'}'}',
                style: AppText.meta(color: context.surface.textSecondary)),
            if (samplePlans[i].focus.isNotEmpty)
              Text(samplePlans[i].focus.join(' · '),
                  style: AppText.meta(color: context.surface.textSecondary)),
            Wrap(spacing: AppSpacing.x4, children: [
              _link(context, 'Start ${samplePlans[i].name}',
                  icon: Icons.play_arrow_rounded),
              _link(context, 'View plan')
            ]),
            Divider(color: context.surface.borderSubtle, height: AppSpacing.x1),
          ]));

  Widget _choiceRow(BuildContext context, int i) => Container(
      margin: const EdgeInsets.only(top: AppSpacing.x2),
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
          color: i == _selected
              ? context.surface.surface2
              : context.surface.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: i == _selected
                  ? context.accent.base
                  : context.surface.borderDefault)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
                i == _selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: i == _selected
                    ? context.accent.base
                    : context.surface.textSecondary,
                size: 24)),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(samplePlans[i].name,
              style: AppText.sheetTitle(color: context.surface.textPrimary)),
          Text(
              '${samplePlans[i].exercises.length} ${i == 4 ? 'exercise' : 'exercises'}${i == _selected ? ' · Selected now' : ''}',
              style: AppText.meta(color: context.surface.textSecondary)),
          if (samplePlans[i].focus.isNotEmpty)
            Text(samplePlans[i].focus.join(' · '),
                style: AppText.meta(color: context.surface.textSecondary)),
        ])),
        if (!_isHome)
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded),
              color: context.surface.textSecondary,
              tooltip: 'Routine options'),
      ]));

  Widget _programHeading(BuildContext context, {bool folder = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (folder)
          Row(children: [
            Icon(Icons.folder_open_outlined,
                color: context.accent.base, size: 24),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
                child: Text('Push / Pull / Legs',
                    style: AppText.sectionHeading(
                        color: context.surface.textPrimary))),
            Icon(Icons.expand_less_rounded,
                color: context.surface.textSecondary)
          ])
        else
          Text('Push / Pull / Legs',
              style:
                  AppText.sectionHeading(color: context.surface.textPrimary)),
        const SizedBox(height: AppSpacing.x1),
        Text('Source program · 3 saved routines',
            style: AppText.meta(color: context.surface.textSecondary)),
        const SizedBox(height: AppSpacing.x3),
      ]);

  Widget _sequence(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final i in [0, 1, 2])
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: context.surface.surface2,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: i == 2
                                ? context.accent.base
                                : context.surface.borderEmphasis)),
                    child: Text('${i + 1}',
                        style: AppText.meta(
                            color: i == 2
                                ? context.accent.base
                                : context.surface.textSecondary))),
                const SizedBox(height: AppSpacing.x1),
                Text(samplePlans[i].name.split(' ').first,
                    style: AppText.body(
                        color: i == 2
                            ? context.surface.textPrimary
                            : context.surface.textSecondary)),
                Text(
                    i == 1
                        ? 'Last logged'
                        : i == 2
                            ? 'Suggested'
                            : 'Saved order',
                    style:
                        AppText.caption(color: context.surface.textSecondary)),
              ])),
      ]);

  Widget _empty(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            _isHome
                ? (fixtureState == LaunchState.empty
                    ? 'Your first session starts here'
                    : 'No saved routine to start')
                : 'Build your training library',
            style: AppText.titleLarge(color: context.surface.textPrimary)),
        const SizedBox(height: AppSpacing.x3),
        Text(
            _isHome
                ? 'Log a freestyle session, or add a routine to train from a plan.'
                : 'Browse programs or create a routine. Imported training days stay together.',
            style: AppText.body(color: context.surface.textSecondary)),
        const SizedBox(height: AppSpacing.x6),
        _primary(context, _isHome ? 'Start freestyle' : 'Browse programs'),
        const SizedBox(height: AppSpacing.x2),
        _link(context, _isHome ? 'Browse programs' : 'New routine',
            icon: Icons.add_rounded),
        if (_isHome) ...[
          _link(context, 'Routine library', icon: Icons.chevron_right_rounded),
          const SizedBox(height: AppSpacing.x6),
          _weekly(context),
          const SizedBox(height: AppSpacing.x6),
          _recent(context),
        ],
      ]);

  Widget _error(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline_rounded,
            color: context.surface.textSecondary, size: 32),
        const SizedBox(height: AppSpacing.x3),
        Text("Couldn't load your routines",
            style: AppText.titleLarge(color: context.surface.textPrimary)),
        const SizedBox(height: AppSpacing.x2),
        Text('A routine and previous-set context are unavailable.',
            style: AppText.body(color: context.surface.textSecondary)),
        const SizedBox(height: AppSpacing.x4),
        _primary(context, 'Try again', icon: Icons.refresh_rounded),
        if (_isHome) ...[
          const SizedBox(height: AppSpacing.x4),
          _link(context, 'Start freestyle', icon: Icons.play_arrow_rounded),
          const SizedBox(height: AppSpacing.x6),
          Text('History unavailable',
              style:
                  AppText.sectionHeading(color: context.surface.textPrimary)),
          _link(context, 'Retry history', icon: Icons.refresh_rounded),
        ],
      ]);

  Widget _weekly(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            fixtureState == LaunchState.error
                ? 'Weekly progress unavailable'
                : 'This week · ${fixtureState == LaunchState.returning || fixtureState == LaunchState.noRoutine ? 2 : 0} of 3 training days',
            style: AppText.body(color: context.surface.textSecondary)),
        const SizedBox(height: AppSpacing.x2),
        LinearProgressIndicator(
            value: fixtureState == LaunchState.returning ||
                    fixtureState == LaunchState.noRoutine
                ? 2 / 3
                : 0,
            minHeight: 4,
            color: context.accent.base,
            backgroundColor: context.surface.surface2),
      ]);

  Widget _recent(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('Last session',
                  style: AppText.sectionHeading(
                      color: context.surface.textPrimary))),
          _link(context, 'History')
        ]),
        if (fixtureState == LaunchState.empty ||
            fixtureState == LaunchState.lowData)
          Text('No workouts logged yet.',
              style: AppText.body(color: context.surface.textSecondary))
        else ...[
          Text(
              'Pull A · ${fixtureState == LaunchState.inactive ? '14 Sep' : '30 Sep'}',
              style: AppText.sheetTitle(color: context.surface.textPrimary)),
          const SizedBox(height: AppSpacing.x1),
          Text('48 min · 5 exercises · 3,850 kg volume',
              style: AppText.meta(color: context.surface.textSecondary)
                  .copyWith(fontFeatures: kTabular)),
        ],
      ]);

  Widget _utilities(BuildContext context) =>
      Wrap(spacing: AppSpacing.x4, children: [
        _link(context, 'Log freestyle', icon: Icons.add_rounded),
        _link(context, 'History', icon: Icons.history_rounded),
      ]);

  Widget _kicker(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Text(text,
          style: AppText.caption(color: context.accent.base)
              .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)));

  Widget _panel(BuildContext context, Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
          color: context.surface.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.card)),
      child: child);

  Widget _primary(BuildContext context, String text,
          {IconData icon = Icons.play_arrow_rounded}) =>
      SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                  backgroundColor: context.accent.base,
                  foregroundColor: context.accent.onAccent,
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  minimumSize: const Size(48, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.buttonPrimary))),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 24),
                const SizedBox(width: AppSpacing.x2),
                Flexible(
                    child: Text(text,
                        textAlign: TextAlign.center,
                        style: AppText.button(color: context.accent.onAccent)))
              ])));

  Widget _link(BuildContext context, String text, {IconData? icon}) =>
      TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
              foregroundColor: context.surface.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
              minimumSize: const Size(48, 48)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.x2)
            ],
            Flexible(
                child: Text(text,
                    style: AppText.body(color: context.surface.textSecondary)))
          ]));
}
