// Your tiny totals DTO (unchanged)

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
