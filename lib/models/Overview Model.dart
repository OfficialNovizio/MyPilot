// Your tiny totals DTO (unchanged)
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
    pay:   (j['pay']   as num?)?.toDouble(),
  );
  Map<String, dynamic> toJson() =>
      {'jobId': jobId, 'jobName': jobName, 'colorHex': colorHex, 'hours': hours, 'pay': pay};
}

// Minimal period bucket for charts/cards
class PeriodRow {
  final DateTime start, end, deposit;
  final double hours, overtime, gross, net;
  const PeriodRow({
    required this.start, required this.end, required this.deposit,
    required this.hours, required this.overtime, required this.gross, required this.net,
  });

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'deposit': deposit.toIso8601String(),
    'hours': hours, 'overtime': overtime, 'gross': gross, 'net': net
  };
}

// One object your widget needs: totals + series + comparisons
class CombinedOverview {
  final CombinedRow totals;         // <- embeds your CombinedRow
  final List<PeriodRow> series;     // ordered oldest → newest
  final DateTime? nextDeposit;
  final double vsLastPct;           // % vs previous period on selected metric
  final double vsAvg3Pct;           // % vs avg of last 3 periods
  const CombinedOverview({
    required this.totals,
    required this.series,
    required this.nextDeposit,
    required this.vsLastPct,
    required this.vsAvg3Pct,
  });

  Map<String, dynamic> toJson() => {
    'totals': totals.toJson(),
    'series': series.map((e) => e.toJson()).toList(),
    'nextDeposit': nextDeposit?.toIso8601String(),
    'vsLastPct': vsLastPct,
    'vsAvg3Pct': vsAvg3Pct,
  };
}
