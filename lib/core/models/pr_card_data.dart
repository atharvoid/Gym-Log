import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'personal_record.dart';
import '../utils/units.dart';
import '../utils/formatters.dart';

/// The category/type of milestone displayed on the PR share card.
enum PrCardType {
  estimated1rm,
  weight,
  reps,
  volume,
  streak,
  duration,
  distance,
  pace,
  firstEver;

  String get label => switch (this) {
        PrCardType.estimated1rm => 'ESTIMATED 1RM',
        PrCardType.weight => 'MAX WEIGHT PR',
        PrCardType.reps => 'REP PR',
        PrCardType.volume => 'VOLUME RECORD',
        PrCardType.streak => 'CONSISTENCY RECORD',
        PrCardType.duration => 'HOLD DURATION PR',
        PrCardType.distance => 'MAX DISTANCE',
        PrCardType.pace => 'BEST PACE',
        PrCardType.firstEver => 'FIRST RECORDED LIFT',
      };
}

/// Privacy preferences for public story sharing.
/// Lifter name and bodyweight default to OFF per DELT privacy doctrine.
@immutable
class PrCardPrivacy {
  final bool showName;
  final bool showBodyweight;
  final bool showDate;

  const PrCardPrivacy({
    this.showName = false,
    this.showBodyweight = false,
    this.showDate = true,
  });

  PrCardPrivacy copyWith({
    bool? showName,
    bool? showBodyweight,
    bool? showDate,
  }) {
    return PrCardPrivacy(
      showName: showName ?? this.showName,
      showBodyweight: showBodyweight ?? this.showBodyweight,
      showDate: showDate ?? this.showDate,
    );
  }
}

/// Standalone, immutable data model required to render a DELT share card.
/// Fully reproducible from DB records (historical workout sessions) or live celebrations.
@immutable
class PrCardData {
  /// Exercise name, e.g. "Barbell Bench Press"
  final String exerciseName;

  /// Primary milestone type
  final PrCardType prType;

  /// Main hero number, e.g. "102.5", "140", "22", "90"
  final String heroValue;

  /// Primary unit, e.g. "KG", "LBS", "REPS", "SEC"
  final String unit;

  /// Rep count if applicable to hero display (e.g. 5 for "102.5 kg × 5")
  final int? reps;
  final bool estimated;
  final String? loggedSetText;

  /// One-line kicker / milestone tag, e.g. "2-PLATE CLUB", "ALL-TIME BEST", "100-DAY STREAK"
  final String? milestoneTag;

  /// Delta vs previous performance, e.g. "+5 kg vs prior", "+0 kg / +3 reps", "First Recorded Lift"
  final String deltaText;

  /// Timestamp of the accomplishment
  final DateTime date;

  /// Optional bodyweight in kg (if logged)
  final double? bodyweightKg;

  /// Display name of the lifter
  final String? lifterName;

  /// Active consistency streak in days (if applicable)
  final int? streakDays;

  /// Session total volume in kg (if applicable)
  final double? totalVolumeKg;

  /// Plate math string (e.g. "20 + 20 + 10 + 2.5 kg per side")
  final String? plateBreakdown;

  /// Active privacy preferences
  final PrCardPrivacy privacy;

  const PrCardData({
    required this.exerciseName,
    required this.prType,
    required this.heroValue,
    required this.unit,
    this.reps,
    this.estimated = false,
    this.loggedSetText,
    this.milestoneTag,
    required this.deltaText,
    required this.date,
    this.bodyweightKg,
    this.lifterName,
    this.streakDays,
    this.totalVolumeKg,
    this.plateBreakdown,
    this.privacy = const PrCardPrivacy(),
  });

  /// Formatted date string conforming to DESIGN.md editorial style (e.g. "1 OCT 2026")
  String get formattedDate =>
      DateFormat('d MMM yyyy').format(date).toUpperCase();

  bool get isEstimate => estimated || prType == PrCardType.estimated1rm;
  String get metricLabel => isEstimate ? 'Estimated 1RM' : prType.label;
  String get heroUnit => !isEstimate &&
          (prType == PrCardType.weight || prType == PrCardType.firstEver) &&
          (unit.toUpperCase() == 'KG' || unit.toUpperCase() == 'LBS') &&
          reps != null &&
          reps! > 0
      ? '$unit × $reps'
      : unit;
  String get contextText => isEstimate
      ? '$deltaText\n${loggedSetText ?? 'Logged set unavailable'}'
      : deltaText;

  /// Formatted hero line: e.g. "102.5 KG × 5" or "140 KG" or "22 REPS"
  String get heroDisplay {
    return '$heroValue $heroUnit';
  }

  PrCardData copyWith({
    String? exerciseName,
    PrCardType? prType,
    String? heroValue,
    String? unit,
    int? reps,
    bool? estimated,
    String? loggedSetText,
    String? milestoneTag,
    String? deltaText,
    DateTime? date,
    double? bodyweightKg,
    String? lifterName,
    int? streakDays,
    double? totalVolumeKg,
    String? plateBreakdown,
    PrCardPrivacy? privacy,
  }) {
    return PrCardData(
      exerciseName: exerciseName ?? this.exerciseName,
      prType: prType ?? this.prType,
      heroValue: heroValue ?? this.heroValue,
      unit: unit ?? this.unit,
      reps: reps ?? this.reps,
      estimated: estimated ?? this.estimated,
      loggedSetText: loggedSetText ?? this.loggedSetText,
      milestoneTag: milestoneTag ?? this.milestoneTag,
      deltaText: deltaText ?? this.deltaText,
      date: date ?? this.date,
      bodyweightKg: bodyweightKg ?? this.bodyweightKg,
      lifterName: lifterName ?? this.lifterName,
      streakDays: streakDays ?? this.streakDays,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      plateBreakdown: plateBreakdown ?? this.plateBreakdown,
      privacy: privacy ?? this.privacy,
    );
  }

  /// Construct a [PrCardData] from a detected [PersonalRecord] and session context.
  factory PrCardData.fromPersonalRecord({
    required PersonalRecord pr,
    required DateTime sessionDate,
    int? reps,
    double? bodyweightKg,
    String? lifterName,
    int? streakDays,
    bool isImperial = false,
  }) {
    final unit = isImperial ? 'LBS' : 'KG';
    final displayUnit = isImperial ? 'lbs' : 'kg';

    String formatVal(double v) {
      final scaled = kgToDisplay(v, displayUnit);
      return scaled == scaled.truncateToDouble()
          ? scaled.toInt().toString()
          : scaled.toStringAsFixed(1);
    }

    PrCardType cardType;
    String heroVal;
    String delta;
    String? tag;

    switch (pr.type) {
      case PersonalRecordType.estimatedOneRepMax:
        cardType = pr.previousValue == null
            ? PrCardType.firstEver
            : PrCardType.estimated1rm;
        heroVal = formatVal(pr.value);
        if (pr.previousValue != null && pr.previousValue! > 0) {
          final diff = kgToDisplay(pr.value - pr.previousValue!, displayUnit);
          final diffStr = diff == diff.truncateToDouble()
              ? diff.toInt().toString()
              : diff.toStringAsFixed(1);
          delta = '+$diffStr $unit vs previous best';
        } else {
          delta = 'First Recorded Lift';
        }
        tag = 'ALL-TIME BEST';
        break;

      case PersonalRecordType.maxWeight:
        cardType =
            pr.previousValue == null ? PrCardType.firstEver : PrCardType.weight;
        heroVal = formatVal(pr.value);
        if (pr.previousValue != null && pr.previousValue! > 0) {
          final diff = kgToDisplay(pr.value - pr.previousValue!, displayUnit);
          final diffStr = diff == diff.truncateToDouble()
              ? diff.toInt().toString()
              : diff.toStringAsFixed(1);
          delta = '+$diffStr $unit vs previous best';
        } else {
          delta = 'First Recorded Lift';
        }
        tag = 'HEAVIEST LOAD';
        break;

      case PersonalRecordType.maxReps:
        cardType = PrCardType.reps;
        heroVal = pr.value.toInt().toString();
        if (pr.previousValue != null && pr.previousValue! > 0) {
          final diff = (pr.value - pr.previousValue!).toInt();
          delta = '+$diff reps at this load';
        } else {
          delta = 'Rep PR';
        }
        tag = 'REP RECORD';
        break;

      case PersonalRecordType.maxDuration:
        cardType = PrCardType.duration;
        heroVal = '${pr.value.toInt()}';
        delta = pr.previousValue != null
            ? '+${(pr.value - pr.previousValue!).toInt()}s vs prior'
            : 'First Record';
        tag = 'MAX HOLD';
        break;

      case PersonalRecordType.maxDistance:
        cardType = PrCardType.distance;
        heroVal = pr.value.toStringAsFixed(1);
        delta = 'New Milestone';
        tag = 'RECORD';
        break;
      case PersonalRecordType.bestPace:
        cardType = PrCardType.pace;
        heroVal = MeasurementFormatter.formatPaceFromSecondsPerMeter(pr.value)
            .split(' ')
            .first;
        delta = 'New Milestone';
        tag = 'RECORD';
        break;
    }

    return PrCardData(
      exerciseName: pr.exerciseName,
      prType: cardType,
      heroValue: heroVal,
      unit: switch (pr.type) {
        PersonalRecordType.maxReps => 'REPS',
        PersonalRecordType.maxDuration => 'SEC',
        PersonalRecordType.maxDistance => pr.unit.toUpperCase(),
        PersonalRecordType.bestPace => '/KM',
        PersonalRecordType.estimatedOneRepMax ||
        PersonalRecordType.maxWeight =>
          unit,
      },
      reps: reps ?? pr.loggedReps,
      estimated: pr.type == PersonalRecordType.estimatedOneRepMax,
      loggedSetText: pr.type == PersonalRecordType.estimatedOneRepMax &&
              pr.loggedWeightKg != null &&
              pr.loggedReps != null
          ? 'Logged: ${formatWeight(pr.loggedWeightKg!, displayUnit)} $unit × ${pr.loggedReps} reps'
          : null,
      milestoneTag: tag,
      deltaText: delta,
      date: sessionDate,
      bodyweightKg: bodyweightKg,
      lifterName: lifterName,
      streakDays: streakDays,
    );
  }
}
