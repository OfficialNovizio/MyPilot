class TaxConfig {
  final String jobId;

  // Percent-of-gross
  double incomeTaxPct;
  double cppPct;
  double eiPct;
  double otherPct;

  // Fixed deductions
  double fixedMonthly;          // once per month
  double fixedPerCheque;        // *each* deposit for this job in the month

  // Optional one-offs keyed by the *deposit date* (YYYY-MM-DD) in that month
  Map<String, double> oneOffByDepositYmd;
  final double postTaxExpensePct;

  TaxConfig({
    required this.jobId,
    this.incomeTaxPct = 0.0,
    this.cppPct = 0.0,
    this.eiPct = 0.0,
    this.otherPct = 0.0,
    this.fixedMonthly = 0.0,
    this.fixedPerCheque = 0.0,
    this.postTaxExpensePct = 0,
    Map<String, double>? oneOffByDepositYmd,
  }) : oneOffByDepositYmd = oneOffByDepositYmd ?? {};

  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'incomeTaxPct': incomeTaxPct,
    'cppPct': cppPct,
    'eiPct': eiPct,
    'otherPct': otherPct,
    'fixedMonthly': fixedMonthly,
    'fixedPerCheque': fixedPerCheque,
    'postTaxExpensePct': postTaxExpensePct,
    'oneOffByDepositYmd': oneOffByDepositYmd,
  };

  factory TaxConfig.fromJson(Map<String, dynamic> j) => TaxConfig(
    jobId: (j['jobId'] ?? '') as String,
    incomeTaxPct: (j['incomeTaxPct'] ?? 0).toDouble(),
    cppPct: (j['cppPct'] ?? 0).toDouble(),
    eiPct: (j['eiPct'] ?? 0).toDouble(),
    otherPct: (j['otherPct'] ?? 0).toDouble(),
    fixedMonthly: (j['fixedMonthly'] ?? 0).toDouble(),
    fixedPerCheque: (j['fixedPerCheque'] ?? 0).toDouble(),
    postTaxExpensePct: (j['postTaxExpensePct'] as num?)?.toDouble() ?? 0,
    oneOffByDepositYmd: Map<String, double>.from(
      (j['oneOffByDepositYmd'] ?? {}).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
    ),
  );
}
