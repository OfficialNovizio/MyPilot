// lib/seed/tax_seed.dart
// Drop this file into your Flutter project at: lib/seed/tax_seed.dart
// Then, in AppController._load(), if taxes is empty, prefill with defaultTaxConfigs().
// Superstore wage suggestion from payslips: 17.95 CAD/hr (set this in Jobs UI).

import '../models/tax_config.dart';

/// Default per-job tax settings synthesized from Superstore payslips you shared.
/// - Income tax currently withheld: ~0% on those slips, so start at 0.0
/// - CPP averages ~5.4–5.9% across slips -> seed with 5.5%
/// - EI ~1.64% on most slips -> seed with 1.64%
/// - Pre-tax union dues avg ≈ 19.82 per cheque; biweekly ≈ 2.17 cheques/month -> ~42.9/month
/// Adjust any of these in the Net Salary screen (pencil icon) later.

List<TaxConfig> defaultTaxConfigs() => [
  TaxConfig(
    jobId: 'superstore',
    incomeTaxPct: 0.0,
    cppPct: 5.5,          // tweak if needed
    eiPct: 1.6,
    otherPct: 0.0,
    fixedMonthly: 40.0,   // union+NDF approx/month if you want
    fixedPerCheque: 0.0,
  ),
  TaxConfig(
    jobId: 'starbucks',
    incomeTaxPct: 0.0,
    cppPct: 4.6,
    eiPct: 1.64,
    otherPct: 0.0,
    fixedMonthly: 0.0,
    fixedPerCheque: 25.0, // Meal adjustment per deposit (avg)
    oneOffByDepositYmd: {
      // add/remove as your month needs
      // '2025-09-24': 56.83,
      // '2025-10-08': 56.83,
    },
  ),
];
