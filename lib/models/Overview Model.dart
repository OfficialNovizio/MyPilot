// Your tiny totals DTO (unchanged)
import 'job.dart';

class CombinedRow {
  int? jobId;
  String? jobName;
  String? colorHex;
  double? hours;
  double? pay;
  CombinedRow({this.jobId, this.jobName, this.colorHex, this.hours, this.pay});

  factory CombinedRow.fromJson(Map<String, dynamic> j) => CombinedRow(
        jobId: j['jobId'],
        jobName: j['jobName'],
        colorHex: j['colorHex'],
        hours: (j['hours'] as num?)?.toDouble(),
        pay: (j['pay'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() => {'jobId': jobId, 'jobName': jobName, 'colorHex': colorHex, 'hours': hours, 'pay': pay};
}

// Minimal period bucket for charts/cards
class PeriodRow {
  final DateTime start, end, deposit;
  final double hours, overtime, gross, net;
  const PeriodRow({
    required this.start,
    required this.end,
    required this.deposit,
    required this.hours,
    required this.overtime,
    required this.gross,
    required this.net,
  });

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'deposit': deposit.toIso8601String(),
        'hours': hours,
        'overtime': overtime,
        'gross': gross,
        'net': net
      };
}

// One object your widget needs: totals + series + comparisons
class CombinedOverview {
  final CombinedRow totals; // <- embeds your CombinedRow
  final List<PeriodRow> series; // ordered oldest → newest
  final DateTime? nextDeposit;
  const CombinedOverview({
    required this.totals,
    required this.series,
    required this.nextDeposit,
  });

  Map<String, dynamic> toJson() => {
        'totals': totals.toJson(),
        'series': series.map((e) => e.toJson()).toList(),
        'nextDeposit': nextDeposit?.toIso8601String(),
      };
}

class WeekData {
  final int weekIndex; // 1..5
  final DateTime start;
  final DateTime end;
  double hours;
  double pay;
  JobData? jobData;

  WeekData({
    required this.weekIndex,
    required this.start,
    required this.end,
    this.hours = 0,
    this.pay = 0,
    this.jobData,
  });
  Map<String, dynamic> toJson() => {
        'weekIndex': start,
        'start': end,
        'end': end,
        'hours': hours,
        'pay': pay,
        'jobData': jobData,
      };
}

class MonthStats {
  final double totalsIncome;
  final double totalHours;
  final List<WeekData> series;
  const MonthStats({
    required this.totalsIncome,
    required this.totalHours,
    required this.series,
  });

  Map<String, dynamic> toJson() => {
        'totalsIncome': totalsIncome,
        'totalHours': totalHours,
        'series': series.map((e) => e.toJson()).toList(),
      };
}

class OverviewModel {
  DateTime? month; // anchor month for this overview (e.g., 2025-12-01)

  /// combined across all jobs
  Totals? totals;

  /// one entry per job: totals + weekly rows (weekIndex included)
  List<JobWeekly>? jobs;

  OverviewModel({this.month, this.totals, this.jobs});

  factory OverviewModel.fromJson(Map<String, dynamic> j) => OverviewModel(
        month: DateTime.parse(j['month'] as String),
        totals: Totals.fromJson(j['totals'] as Map<String, dynamic>),
        jobs: (j['jobs'] as List<dynamic>? ?? const []).map((e) => JobWeekly.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'month': month!.toIso8601String(),
        'totals': totals!.toJson(),
        'jobs': jobs!.map((e) => e.toJson()).toList(),
      };
}

class JobWeekly {
  final int jobId;
  final String jobName;
  final String colorHex;

  /// totals for THIS job in the month
  final Totals totals;

  /// weekly rows for THIS job (weekIndex lives here)
  final List<WeekRow> weeks;

  const JobWeekly({
    required this.jobId,
    required this.jobName,
    required this.colorHex,
    required this.totals,
    required this.weeks,
  });

  factory JobWeekly.fromJson(Map<String, dynamic> j) => JobWeekly(
        jobId: (j['jobId'] as num).toInt(),
        jobName: (j['jobName'] as String?) ?? '',
        colorHex: (j['colorHex'] as String?) ?? '#000000',
        totals: Totals.fromJson(j['totals'] as Map<String, dynamic>),
        weeks: (j['weeks'] as List<dynamic>? ?? const []).map((e) => WeekRow.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'jobName': jobName,
        'colorHex': colorHex,
        'totals': totals.toJson(),
        'weeks': weeks.map((e) => e.toJson()).toList(),
      };
}

class WeekRow {
  final int weekIndex; // 1..6 typically
  final DateTime start;
  final DateTime end;
  final double hours;
  final double pay;

  const WeekRow({
    required this.weekIndex,
    required this.start,
    required this.end,
    required this.hours,
    required this.pay,
  });

  factory WeekRow.fromJson(Map<String, dynamic> j) => WeekRow(
        weekIndex: (j['weekIndex'] as num).toInt(),
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        hours: (j['hours'] as num?)?.toDouble() ?? 0.0,
        pay: (j['pay'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'weekIndex': weekIndex,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'hours': hours,
        'pay': pay,
      };
}

class Totals {
  final double hours;
  final double pay;

  const Totals({required this.hours, required this.pay});

  factory Totals.fromJson(Map<String, dynamic> j) => Totals(
        hours: (j['hours'] as num?)?.toDouble() ?? 0.0,
        pay: (j['pay'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {'hours': hours, 'pay': pay};
}
