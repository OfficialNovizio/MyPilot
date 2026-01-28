// expense_insight_logic_v10.dart
// ============================================================================
// INSIGHTS LOGIC (pure functions, no GetX, no storage)
// ----------------------------------------------------------------------------
// Linked with:
// - ExpensesControllerV2.refreshInsights()  (calls gate + deck compute)
//
// Requires your PayCycle data:
// - payCycles: Map<DateTime, PayCell>
// - PayCell must expose:
//     - List<PayJobLine> lines
//     - double totalPay
// - PayJobLine must expose:
//     - DateTime periodStart
//     - DateTime periodEnd
//
// If your PayCell/PayJobLine are different, update the accessors in PayCycleWindow.
// ============================================================================

import '../../../models/Expense Model V2.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
String _md(DateTime d) => "${d.month}/${d.day}";
String _rangeLabel(DateTime a, DateTime b) => "${_md(a)}–${_md(b)}";
String money(num v) => "\$${v.toStringAsFixed(0)}";
int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

bool _inWindow(DateTime d, DateTime start, DateTime end) {
  final dd = _day(d);
  return !dd.isBefore(_day(start)) && !dd.isAfter(_day(end));
}

/// For monthly planned bills: returns next due date starting from an anchor day.
DateTime _nextMonthlyDueFrom(DateTime anchor, int dueDay) {
  final a = _day(anchor);
  int clampDay(int yy, int mm, int d) => d.clamp(1, _daysInMonth(yy, mm));
  final dThis = DateTime(a.year, a.month, clampDay(a.year, a.month, dueDay));
  if (!dThis.isBefore(a)) return dThis;
  final nm = DateTime(a.year, a.month + 1, 1);
  return DateTime(nm.year, nm.month, clampDay(nm.year, nm.month, dueDay));
}

/// Gate model shown by UI when insights are not allowed.
class InsightsGateVM {
  final bool allowed;
  final int daysHave;
  final int daysNeed;
  final String title;
  final String subtitle;

  const InsightsGateVM({
    required this.allowed,
    required this.daysHave,
    required this.daysNeed,
    required this.title,
    required this.subtitle,
  });
}

/// Counts distinct SPEND days and blocks insights until enough real history exists.
///
/// Why this exists:
/// - With 2 planned bills (subscription + internet) you DO NOT want “don’t eat out”.
/// - So we refuse to generate behavior insights without enough spend distribution.
InsightsGateVM buildHistoryGate(
  List<ExpenseItem> expenses, {
  int minDays = 15,
  DateTime? now,
}) {
  final t = _day(now ?? DateTime.now());

  final spent = expenses.where((e) => e.isActive && e.mode == ExpenseMode.spent).toList();

  if (spent.isEmpty) {
    return InsightsGateVM(
      allowed: false,
      daysHave: 0,
      daysNeed: minDays,
      title: "Insights locked",
      subtitle: "Track spending on $minDays different days to unlock insights. (Multiple expenses on the same day count as 1 day.)",
    );
  }

  // Prefer last 30 days
  final start30 = t.subtract(const Duration(days: 30));
  final days30 = <String>{};
  for (final e in spent) {
    if (!_inWindow(e.date, start30, t)) continue;
    days30.add("${e.date.year}-${e.date.month}-${e.date.day}");
  }

  if (days30.length >= minDays) {
    return InsightsGateVM(
      allowed: true,
      daysHave: days30.length,
      daysNeed: minDays,
      title: "Insights unlocked",
      subtitle: "You’ve tracked ${days30.length} spend days — insights are now based on your real spending patterns.",
    );
  }

  // Fallback: all time
  final allDays = <String>{};
  for (final e in spent) {
    allDays.add("${e.date.year}-${e.date.month}-${e.date.day}");
  }

  final have = allDays.length;
  final remaining = (minDays - have).clamp(0, minDays);

  return InsightsGateVM(
    allowed: have >= minDays,
    daysHave: have,
    daysNeed: minDays,
    title: have >= minDays ? "Insights unlocked" : "Insights locked",
    subtitle: have >= minDays
        ? "You’ve tracked $have spend days — insights are now based on your real spending patterns."
        : "You’ve tracked $have/$minDays spend days. Add $remaining more days. (Multiple expenses on the same day count as 1.)",
  );
}

/// Buffer suggestion based on volatility of spent transactions (last 30 days).
double suggestBufferTarget(List<ExpenseItem> expenses, {DateTime? now}) {
  final t = _day(now ?? DateTime.now());
  final start = t.subtract(const Duration(days: 30));
  final daily = <DateTime, double>{};

  for (final e in expenses) {
    if (!e.isActive) continue;
    if (e.mode != ExpenseMode.spent) continue;
    if (!_inWindow(e.date, start, t)) continue;
    final k = _day(e.date);
    daily[k] = (daily[k] ?? 0) + e.amount;
  }

  if (daily.isEmpty) return 40.0;

  final values = daily.values.toList();
  final mean = values.reduce((a, b) => a + b) / values.length;

  double varSum = 0.0;
  for (final v in values) {
    final d = v - mean;
    varSum += d * d;
  }

  final std = (varSum / values.length).sqrtSafe();
  final raw = (2.0 * std) + (0.5 * mean);
  return raw.clamp(40.0, 400.0);
}

extension _Sqrt on double {
  double sqrtSafe() {
    if (!isFinite) return 0.0;
    if (this <= 0) return 0.0;
    double x = this;
    double r = x;
    for (int i = 0; i < 10; i++) {
      r = 0.5 * (r + x / r);
    }
    return r;
  }
}

/// Wraps one payday + its PayCell and exposes normalized windowStart/windowEnd.
class PayCycleWindow {
  final DateTime payDate;
  final dynamic cell; // PayCell from your project

  PayCycleWindow({required this.payDate, required this.cell});

  DateTime get windowStart {
    final lines = cell.lines as List; // List<PayJobLine>
    if (lines.isEmpty) return _day(payDate);
    DateTime minStart = _day(lines.first.periodStart);
    for (final l in lines) {
      final s = _day(l.periodStart);
      if (s.isBefore(minStart)) minStart = s;
    }
    return minStart;
  }

  DateTime get windowEnd => _day(payDate);

  String get id => "${windowStart.millisecondsSinceEpoch}_${windowEnd.millisecondsSinceEpoch}";
  String get label => _rangeLabel(windowStart, windowEnd);
}

/// Creates pay windows for the focused month and only from today onward.
List<PayCycleWindow> buildPayCycleWindowsMonthOnly({
  required DateTime now,
  required DateTime focusedDay,
  required Map<DateTime, dynamic> payCycles, // Map<DateTime, PayCell>
}) {
  final monthStart = _day(DateTime(focusedDay.year, focusedDay.month, 1));
  final monthEnd = _day(DateTime(focusedDay.year, focusedDay.month + 1, 0));

  final cut = _day(now).isBefore(monthStart) ? monthStart : _day(now);

  final keys = payCycles.keys.map(_day).where((d) => !d.isBefore(cut) && !d.isAfter(monthEnd)).toList()..sort((a, b) => a.compareTo(b));

  return keys.map((k) => PayCycleWindow(payDate: k, cell: payCycles[k]!)).toList();
}

/// Focus split for a window: billsDue vs recurring planned vs spent.
class FocusData {
  final List<ExpenseItem> billsDue;
  final List<ExpenseItem> plannedRecurring;
  final List<ExpenseItem> spent;

  final double billsDueTotal;
  final double plannedRecurringTotal;
  final double spentTotal;

  final ExpenseItem? topBill;
  final ExpenseItem? topSpentNonEssential;

  final String confidenceLevel;
  final String confidenceReason;

  const FocusData({
    required this.billsDue,
    required this.plannedRecurring,
    required this.spent,
    required this.billsDueTotal,
    required this.plannedRecurringTotal,
    required this.spentTotal,
    required this.topBill,
    required this.topSpentNonEssential,
    required this.confidenceLevel,
    required this.confidenceReason,
  });
}

/// Splits expenses into window buckets.
FocusData buildFocusForWindow({
  required List<ExpenseItem> expenses,
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  final billsDue = <ExpenseItem>[];
  final plannedRecurring = <ExpenseItem>[];
  final spent = <ExpenseItem>[];

  double billsTotal = 0.0;
  double plannedTotal = 0.0;
  double spentTotal = 0.0;

  int monthlyPlanned = 0;
  int monthlyWithDueDay = 0;

  for (final e in expenses) {
    if (!e.isActive) continue;

    if (e.mode == ExpenseMode.spent) {
      if (_inWindow(e.date, windowStart, windowEnd)) {
        spent.add(e);
        spentTotal += e.amount;
      }
      continue;
    }

    final f = e.frequency;

    if (f == ExpenseFrequency.monthly) {
      monthlyPlanned++;
      if (e.dueDay >= 1) {
        monthlyWithDueDay++;
        final due = _nextMonthlyDueFrom(windowStart, e.dueDay);
        if (_inWindow(due, windowStart, windowEnd)) {
          billsDue.add(e);
          billsTotal += e.amount;
        } else {
          plannedRecurring.add(e);
          plannedTotal += e.amount;
        }
      } else {
        plannedRecurring.add(e);
        plannedTotal += e.amount;
      }
      continue;
    }

    plannedRecurring.add(e);
    plannedTotal += e.amount;
  }

  billsDue.sort((a, b) => b.amount.compareTo(a.amount));
  spent.sort((a, b) => b.amount.compareTo(a.amount));
  plannedRecurring.sort((a, b) => b.amount.compareTo(a.amount));

  final topBill = billsDue.isEmpty ? null : billsDue.first;

  ExpenseItem? topSpentNE;
  for (final s in spent) {
    if (!s.isEssential) {
      topSpentNE = s;
      break;
    }
  }

  String conf;
  String reason;
  if (monthlyPlanned == 0) {
    conf = "High";
    reason = "No monthly planned bills set.";
  } else {
    final missing = monthlyPlanned - monthlyWithDueDay;
    final ratio = monthlyWithDueDay / monthlyPlanned;
    conf = ratio >= 0.8 ? "High" : (ratio >= 0.4 ? "Medium" : "Low");
    reason = "$missing monthly planned bills missing due day.";
  }

  return FocusData(
    billsDue: billsDue,
    plannedRecurring: plannedRecurring,
    spent: spent,
    billsDueTotal: billsTotal,
    plannedRecurringTotal: plannedTotal,
    spentTotal: spentTotal,
    topBill: topBill,
    topSpentNonEssential: topSpentNE,
    confidenceLevel: conf,
    confidenceReason: reason,
  );
}

/// Category summaries from spent items only.
List<LeaksAndSpikesRow> buildLeaksAndSpikes(FocusData f) {
  final byCat = <String, double>{};
  for (final e in f.spent) {
    final c = e.category.trim().isEmpty ? "Other" : e.category.trim();
    byCat[c] = (byCat[c] ?? 0) + e.amount;
  }

  final items = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final out = <LeaksAndSpikesRow>[];

  for (int i = 0; i < items.length && i < 6; i++) {
    final it = items[i];
    final tag = (i == 0)
        ? "spike"
        : (i == 1)
            ? "leak"
            : "ok";
    out.add(LeaksAndSpikesRow(
      title: it.key,
      subtitle: "${money(it.value)} this window",
      trailing: tag,
    ));
  }
  return out;
}

/// Single computed output for one pay window.
class CashflowCompute {
  final InsightsModel insights;
  final FocusData focus;
  final String risk;

  const CashflowCompute({
    required this.insights,
    required this.focus,
    required this.risk,
  });
}

/// Computes insight cards for one window.
/// Keep it “honest”: without enough spend history, gate blocks output.
CashflowCompute computeWindowInsights({
  required List<ExpenseItem> expenses,
  required DateTime windowStart,
  required DateTime payday,
  required double incomeWindow,
  required double bufferTarget,
  required double debtMinimumsWindow,
}) {
  final wStart = _day(windowStart);
  final wEnd = _day(payday);

  final focus = buildFocusForWindow(expenses: expenses, windowStart: wStart, windowEnd: wEnd);

  final plannedBills = focus.billsDueTotal;
  final plannedRecurring = focus.plannedRecurringTotal;
  final spentSoFar = focus.spentTotal;

  final safeRaw = incomeWindow - plannedBills - plannedRecurring - spentSoFar - debtMinimumsWindow - bufferTarget;
  final safeClamped = safeRaw < 0 ? 0.0 : safeRaw;

  final tightThreshold = (bufferTarget * 0.75).clamp(25.0, 75.0);
  final risk = (safeRaw < 0) ? "High" : (safeRaw < tightThreshold ? "Tight" : "Safe");

  final forecastDesc =
      "${_rangeLabel(wStart, wEnd)} is $risk. Safe-to-spend ${money(safeClamped)} after planned ${money(plannedBills + plannedRecurring)} + spent ${money(spentSoFar)} + buffer ${money(bufferTarget)}. Confidence ${focus.confidenceLevel}: ${focus.confidenceReason}";

  final safeToSpend = SafeToSpend(
    amount: safeClamped,
    untilDateMs: wEnd.millisecondsSinceEpoch,
    expectedIncome: incomeWindow,
    plannedBills: plannedBills,
    plannedRecurring: plannedRecurring,
    spentSoFar: spentSoFar,
    debtMinimums: debtMinimumsWindow,
    bufferTarget: bufferTarget,
  );

  final next = (risk == "Safe")
      ? NextBestMove(
          title: "Improve accuracy (set due days)",
          description: focus.confidenceReason,
          actionAmount: 0.0,
          dueDateMs: wEnd.millisecondsSinceEpoch,
        )
      : NextBestMove(
          title: "Protect buffer until ${_md(wEnd)}",
          description: "Forecast is $risk. Keep spending predictable until payday.",
          actionAmount: 0.0,
          dueDateMs: wEnd.millisecondsSinceEpoch,
        );

  final insights = InsightsModel(
    safeToSpend: safeToSpend,
    nextBestMove: next,
    leaksAndSpikes: buildLeaksAndSpikes(focus),
    forecastRisk: ForecastRisk(level: risk, title: "Forecast risk", description: forecastDesc, actions: const []),
    cutsChecklist: CutsChecklist(
      title: "Quick fixes",
      tag: risk,
      bullets: const [
        "Add more spending history to get meaningful category insights.",
        "Set due days for monthly bills for accurate ‘bills due’ forecasting.",
      ],
    ),
  );

  return CashflowCompute(insights: insights, focus: focus, risk: risk);
}

/// One UI item per window.
class WindowDeckItemVM {
  final PayCycleWindow window;
  final double incomeWindow;
  final FocusData focus;
  final InsightsModel insights;

  final double plannedTotal;
  final double spentTotal;
  final String confidence;

  const WindowDeckItemVM({
    required this.window,
    required this.incomeWindow,
    required this.focus,
    required this.insights,
    required this.plannedTotal,
    required this.spentTotal,
    required this.confidence,
  });

  String get windowId => window.id;
  String get windowLabel => window.label;
  DateTime get payday => window.payDate;
}

/// Deck returned to controller/UI.
class InsightsDeckVM {
  final List<WindowDeckItemVM> items;
  final String activeWindowId;

  const InsightsDeckVM({required this.items, required this.activeWindowId});

  WindowDeckItemVM get active => items.firstWhere((x) => x.windowId == activeWindowId, orElse: () => items.first);
}

String pickActiveWindowId(List<PayCycleWindow> windows, DateTime now) {
  final today = _day(now);
  for (final w in windows) {
    if (!w.windowEnd.isBefore(today)) return w.id;
  }
  return windows.isEmpty ? "" : windows.first.id;
}

/// Builds the deck for the focused month.
InsightsDeckVM computeInsightsDeck({
  required List<ExpenseItem> expenses,
  required DateTime focusedDay,
  required Map<DateTime, dynamic> payCycles, // Map<DateTime, PayCell>
  required double bufferTarget,
  required double debtMinimumsWindow,
  DateTime? now,
}) {
  final t = now ?? DateTime.now();

  final windows = buildPayCycleWindowsMonthOnly(
    now: t,
    focusedDay: focusedDay,
    payCycles: payCycles,
  );

  final out = <WindowDeckItemVM>[];

  for (final w in windows) {
    final incomeWindow = (w.cell.totalPay as double?) ?? 0.0;

    final computed = computeWindowInsights(
      expenses: expenses,
      windowStart: w.windowStart,
      payday: w.windowEnd,
      incomeWindow: incomeWindow,
      bufferTarget: bufferTarget,
      debtMinimumsWindow: debtMinimumsWindow,
    );

    final plannedTotal = computed.focus.billsDueTotal + computed.focus.plannedRecurringTotal;

    out.add(WindowDeckItemVM(
      window: w,
      incomeWindow: incomeWindow,
      focus: computed.focus,
      insights: computed.insights,
      plannedTotal: plannedTotal,
      spentTotal: computed.focus.spentTotal,
      confidence: computed.focus.confidenceLevel,
    ));
  }

  return InsightsDeckVM(items: out, activeWindowId: pickActiveWindowId(windows, t));
}

/// Monthly summary (simple + honest).
MonthlySummary computeMonthlySummary(List<ExpenseItem> expenses) {
  double fixedPlanned = 0.0;
  double variableSpent = 0.0;

  double toMonthly(double amt, String freq, String mode) {
    if (mode == ExpenseMode.spent) return amt;
    switch (freq) {
      case ExpenseFrequency.monthly:
        return amt;
      case ExpenseFrequency.weekly:
        return amt * 4.345;
      case ExpenseFrequency.biweekly:
        return amt * 2.0;
      default:
        return amt;
    }
  }

  for (final e in expenses) {
    if (!e.isActive) continue;
    if (e.mode == ExpenseMode.spent) {
      variableSpent += e.amount;
    } else {
      fixedPlanned += toMonthly(e.amount, e.frequency, e.mode);
    }
  }
  return MonthlySummary(
    fixedPlanned: fixedPlanned,
    variableSpent: variableSpent,
    total: fixedPlanned + variableSpent,
    note: "Planned recurring (monthly equiv) + spent transactions (actual)",
  );
}
