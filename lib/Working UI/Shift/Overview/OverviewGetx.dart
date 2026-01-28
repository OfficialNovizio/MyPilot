import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/Overview Model.dart';
import '../../../models/shift.dart';
import '../../Constants.dart';
import '../../Controllers.dart';

/// ---------------------------------------------------------------------------
/// INSIGHTS (GetX Controller)
/// ---------------------------------------------------------------------------

class OverviewInsightsController extends GetxController {
  /// You set these from your Overview screen when month changes.
  Rxn<OverviewModel>? currentMonthOverView = Rxn<OverviewModel>();
  Rxn<OverviewModel>? previousMonthOverView = Rxn<OverviewModel>();
  Rxn<ShiftMonth>? currentMonthShift = Rxn<ShiftMonth>();

  /// settings can be changed from user preferences
  RxList<InsightCardModel>? insights = <InsightCardModel>[].obs;
  RxBool? minimumShifts = false.obs;

  /// how many to show in UI
  final RxInt maxItems = 5.obs;
  Rx<DateTime> selectedMonth = Rx<DateTime>(DateTime.now());

  void shiftMonth(int delta) {
    final next = DateTime(selectedMonth.value.year, selectedMonth.value.month + delta, 1);
    final nextMonthData = shift.getCurrentData(next);
    if (nextMonthData == null) {
      showSnackBar("No data", "No shift records for ${monthName(next)}.");
      return;
    }

    selectedMonth.value = next;
    currentMonthShift!.value = nextMonthData;
    // current overview
    currentMonthOverView!.value = shift.buildOverviewForMonth(nextMonthData);

    // previous overview (null-safe)
    final prevDate = DateTime(next.year, next.month - 1, 1);
    final prevData = shift.getCurrentData(prevDate);
    previousMonthOverView!.value =
        prevData == null ? OverviewModel(month: prevDate, totals: Totals(hours: 0, pay: 0), jobs: const []) : shift.buildOverviewForMonth(prevData);
    insights!.value = computeOverviewInsights(
      current: currentMonthOverView!.value,
      previous: previousMonthOverView!.value, // can be null
      shiftMonth: currentMonthShift!.value, // you said always available
      settings: InsightSettings(
        monthlyIncomeGoal: 2500, // or from user prefs
        safeWeeklyHoursLimit: 50, // or from user prefs
        otThreshold: 40,
      ),
      now: DateTime.now(),
    );
    insights!.refresh();
  }

  String formatMonth() => '${const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][selectedMonth.value.month - 1]} ${selectedMonth.value.year}';

// usage:
  void goToPreviousMonth() => shiftMonth(-1);
  void goToNextMonth() => shiftMonth(1);
}

// overview_insights_v2.dart
//
// Drop-in overview insights engine (4–8 cards), month-safe (supports month picker).
//
// ✅ Uses your existing models:
//   OverviewModel -> totals (hours, pay), jobs(List<JobWeekly>) -> weeks(List<WeekRow>)
//   ShiftMonth -> dates(List<ShiftDay>) -> data(List<AllShifts>) + totalDayIncome + totalWorkingHour
//
// ⚠️ Adjust the ProjectColors import/path to your project.
// If you don't want UI colors in logic, remove iconBg/iconColor and map in UI.

// TODO: fix import to your project
// import 'package:your_app/constants/project_colors.dart';

enum InsightSeverity { good, info, warn }

class InsightCardModel {
  final String id;
  final InsightSeverity severity;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final int score;

  const InsightCardModel({
    required this.id,
    required this.severity,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.score,
  });
}

class InsightSettings {
  double? monthlyIncomeGoal; // e.g. 2500
  double? safeWeeklyHoursLimit; // e.g. 50
  double otThreshold; // e.g. 40
  bool enableRateGapInsight; // show job rate gap
  bool enableSpikeInsight; // show anomalies
  int minShiftsForPatterns; // e.g. 10

  InsightSettings({
    this.monthlyIncomeGoal = 2500,
    this.safeWeeklyHoursLimit = 50,
    this.otThreshold = 40,
    this.enableRateGapInsight = true,
    this.enableSpikeInsight = true,
    this.minShiftsForPatterns = 10,
  });

  InsightSettings copyWith({
    double? monthlyIncomeGoal,
    double? safeWeeklyHoursLimit,
    double? otThreshold,
    bool? enableRateGapInsight,
    bool? enableSpikeInsight,
    int? minShiftsForPatterns,
  }) {
    return InsightSettings(
      monthlyIncomeGoal: monthlyIncomeGoal ?? this.monthlyIncomeGoal,
      safeWeeklyHoursLimit: safeWeeklyHoursLimit ?? this.safeWeeklyHoursLimit,
      otThreshold: otThreshold ?? this.otThreshold,
      enableRateGapInsight: enableRateGapInsight ?? this.enableRateGapInsight,
      enableSpikeInsight: enableSpikeInsight ?? this.enableSpikeInsight,
      minShiftsForPatterns: minShiftsForPatterns ?? this.minShiftsForPatterns,
    );
  }
}

/* -----------------------------
   HELPERS (format + dates)
------------------------------ */

DateTime _monthAnchor(DateTime d) => DateTime(d.year, d.month, 1);
bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

String _money(num v) => "\$${v.toStringAsFixed(0)}";
String _pct(num v) => "${v.toStringAsFixed(0)}%";

int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

String _md(DateTime d) => "${d.month}/${d.day}";
String _rangeLabel(DateTime a, DateTime b) => "${_md(a)}–${_md(b)}";

double _safeDiv(double num, double den) => (den <= 0) ? 0.0 : (num / den);

int _clampScore(num s) => s.isNaN ? 0 : s.toInt().clamp(0, 100);

DateTime? _tryParseDate(dynamic s) {
  if (s == null) return null;
  if (s is DateTime) return s;
  if (s is String) return DateTime.tryParse(s);
  return DateTime.tryParse(s.toString());
}

// Streak of consecutive WORKED days in month (by ShiftDay)
int _longestStreak(List<_ShiftDayLite> workedDays) {
  if (workedDays.isEmpty) return 0;
  workedDays.sort((a, b) => a.date.compareTo(b.date));
  int best = 1;
  int cur = 1;
  for (int i = 1; i < workedDays.length; i++) {
    final prev = workedDays[i - 1].date;
    final now = workedDays[i].date;
    final diff = now.difference(prev).inDays;
    if (diff == 1) {
      cur++;
      best = max(best, cur);
    } else {
      cur = 1;
    }
  }
  return best;
}

// Replace these with your palette if you want.
Color _goodBg() => Colors.green.withOpacity(.25);
Color _goodFg() => Colors.green;
Color _infoBg() => Colors.green.withOpacity(.18);
Color _infoFg() => Colors.green;
Color _warnBg() => Colors.red.withOpacity(.22);
Color _warnFg() => Colors.red;
Color _yellowBg() => Colors.orange.withOpacity(.22);
Color _yellowFg() => Colors.orange;

/* -----------------------------
   SHIFT MONTH LITE ADAPTER
------------------------------ */

class _ShiftDayLite {
  final DateTime date;
  final int shiftCount;
  final double dayIncome;
  final double dayHours;

  const _ShiftDayLite({
    required this.date,
    required this.shiftCount,
    required this.dayIncome,
    required this.dayHours,
  });
}

/// Converts your ShiftMonth into a month-level day list.
/// Assumes ShiftDay.date is a "YYYY-MM-DD" string.
/// Uses ShiftDay.totalDayIncome/totalWorkingHour if present; falls back to summing shift incomes if needed.

Iterable _asIterable(dynamic v) {
  if (v == null) return const [];
  if (v is Iterable) return v;

  // GetX patterns (just in case)
  // RxList has `.toList()` via ListMixin usually, but some wrappers keep `.value`
  try {
    final val = (v as dynamic).value;
    if (val is Iterable) return val;
  } catch (_) {}

  return const [];
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  return double.tryParse(s.replaceAll(RegExp(r'[^0-9\.\-]'), '')) ?? 0.0;
}

double _sumShiftIncome(Iterable shifts) {
  double sum = 0;
  for (final sh in shifts) {
    // your shift model: sh.income
    try {
      sum += _toDouble((sh as dynamic).income);
    } catch (_) {}
  }
  return sum;
}

List<_ShiftDayLite> _extractShiftDays({
  required dynamic shiftMonth, // ShiftMonth?
}) {
  if (shiftMonth == null) return const [];

  final rawDates = _asIterable((shiftMonth as dynamic).dates);
  if (rawDates.isEmpty) return const [];

  final out = <_ShiftDayLite>[];

  for (final d in rawDates) {
    // 1) date from ShiftDay.date
    DateTime? dt = _tryParseDate((d as dynamic).date);

    // 2) fallback: if ShiftDay.date is weird, try first shift's date/start
    final shiftsIt = _asIterable((d as dynamic).data);
    if (dt == null && shiftsIt.isNotEmpty) {
      final first = shiftsIt.first;
      dt = _tryParseDate((first as dynamic).date) ?? _tryParseDate((first as dynamic).start);
    }
    if (dt == null) continue;

    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    final shiftCount = shiftsIt.length;

    // Prefer cached totals, but handle string/num
    final dayIncomeRaw = (d as dynamic).totalDayIncome;
    final dayHoursRaw = (d as dynamic).totalWorkingHour;

    final dayIncome = (dayIncomeRaw != null) ? _toDouble(dayIncomeRaw) : _sumShiftIncome(shiftsIt);
    final dayHours = (dayHoursRaw != null) ? _toDouble(dayHoursRaw) : 0.0;

    out.add(_ShiftDayLite(
      date: dateOnly,
      shiftCount: shiftCount,
      dayIncome: dayIncome,
      dayHours: dayHours,
    ));
  }

  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

/* -----------------------------
   WEEK AGGREGATION (from OverviewModel weeks)
------------------------------ */

class _WeekAgg {
  final int weekIndex;
  final DateTime start;
  final DateTime end;
  double hours;
  double pay;

  _WeekAgg({
    required this.weekIndex,
    required this.start,
    required this.end,
    required this.hours,
    required this.pay,
  });
}

/// Aggregate weekly totals across all jobs by weekIndex.
/// Uses WeekRow.start/end for labels (first seen per index).
List<_WeekAgg> _aggregateWeeks(dynamic current /* OverviewModel */) {
  final jobs = current.jobs as List? ?? const [];
  if (jobs.isEmpty) return const [];

  final map = <int, _WeekAgg>{};

  for (final j in jobs) {
    final weeks = j.weeks as List? ?? const [];
    for (final w in weeks) {
      final idx = (w.weekIndex as num?)?.toInt() ?? 0;
      if (idx <= 0) continue;

      final start = w.start as DateTime?;
      final end = w.end as DateTime?;
      if (start == null || end == null) continue;

      final hours = (w.hours as num?)?.toDouble() ?? 0.0;
      final pay = (w.pay as num?)?.toDouble() ?? 0.0;

      map[idx] ??= _WeekAgg(
        weekIndex: idx,
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(end.year, end.month, end.day),
        hours: 0.0,
        pay: 0.0,
      );

      map[idx]!.hours += hours;
      map[idx]!.pay += pay;
    }
  }

  final list = map.values.toList();
  list.sort((a, b) => a.start.compareTo(b.start));
  return list;
}

/* -----------------------------
   JOB PICKERS (top pay + rate gap)
------------------------------ */

class _JobPick {
  final dynamic job; // JobWeekly
  final double pay;
  final double hours;
  final double rate;

  const _JobPick({required this.job, required this.pay, required this.hours, required this.rate});
}

_JobPick? _topPayJob(dynamic current /* OverviewModel */) {
  final jobs = current.jobs as List? ?? const [];
  if (jobs.isEmpty) return null;

  dynamic best;
  double bestPay = -1;

  for (final j in jobs) {
    final p = (j.totals?.pay as num?)?.toDouble() ?? 0.0;
    if (p > bestPay) {
      bestPay = p;
      best = j;
    }
  }
  if (best == null) return null;

  final hours = (best.totals?.hours as num?)?.toDouble() ?? 0.0;
  final pay = (best.totals?.pay as num?)?.toDouble() ?? 0.0;
  final rate = _safeDiv(pay, hours);
  return _JobPick(job: best, pay: pay, hours: hours, rate: rate);
}

List<_JobPick> _jobRates(dynamic current /* OverviewModel */) {
  final jobs = current.jobs as List? ?? const [];
  final out = <_JobPick>[];
  for (final j in jobs) {
    final hours = (j.totals?.hours as num?)?.toDouble() ?? 0.0;
    final pay = (j.totals?.pay as num?)?.toDouble() ?? 0.0;
    if (hours <= 0 || pay <= 0) continue;
    out.add(_JobPick(job: j, pay: pay, hours: hours, rate: pay / hours));
  }
  out.sort((a, b) => b.rate.compareTo(a.rate));
  return out;
}

/* -----------------------------
   MAIN: computeOverviewInsights (4–8 cards)
------------------------------ */

List<InsightCardModel> computeOverviewInsights({
  required dynamic current, // OverviewModel
  required dynamic previous, // OverviewModel?
  required dynamic shiftMonth, // ShiftMonth (always available per you)
  InsightSettings? settings,
  DateTime? now,
}) {
  final s = settings ?? InsightSettings();
  final t = now ?? DateTime.now();

  final month = current.month as DateTime?;
  final anchor = month == null ? _monthAnchor(t) : _monthAnchor(month);
  final isCurrentMonth = _sameMonth(anchor, _monthAnchor(t));

  final monthPay = (current.totals?.pay as num?)?.toDouble() ?? 0.0;
  final monthHours = (current.totals?.hours as num?)?.toDouble() ?? 0.0;
  final monthRate = _safeDiv(monthPay, monthHours);

  final days = _extractShiftDays(shiftMonth: shiftMonth);
  final workedDays = days.where((d) => d.shiftCount > 0).toList();
  final daysWorked = workedDays.length;
  final shiftCount = workedDays.fold<int>(0, (p, d) => p + d.shiftCount);
  final avgShiftHours = (shiftCount <= 0) ? 0.0 : _safeDiv(monthHours, shiftCount.toDouble());
  final streak = _longestStreak(workedDays);

  final weeks = _aggregateWeeks(current);

  final cards = <InsightCardModel>[];

  // -------------------------
  // BASE 4 (always produce 4)
  // -------------------------

  // Base 1) Month Summary
  cards.add(
    InsightCardModel(
      id: "month_summary",
      severity: InsightSeverity.info,
      icon: Icons.insights_outlined,
      iconBg: _infoBg(),
      iconColor: _infoFg(),
      title: "Total: ${_money(monthPay)} this month",
      subtitle: "${monthHours.toStringAsFixed(0)} hours • Avg ${_money(monthRate)}/hr",
      score: 100,
    ),
  );

  // Base 2) Top Job Contribution OR onboarding if no jobs
  final topJob = _topPayJob(current);
  if (topJob == null) {
    cards.add(
      InsightCardModel(
        id: "onboarding_add_job",
        severity: InsightSeverity.info,
        icon: Icons.work_outline,
        iconBg: _infoBg(),
        iconColor: _infoFg(),
        title: "Add a job to unlock job breakdowns",
        subtitle: "Then your overview can show top job + weekly splits.",
        score: 90,
      ),
    );
  } else {
    final topName = (topJob.job.jobName ?? "").toString().isEmpty ? "Top job" : (topJob.job.jobName ?? "").toString();
    final share = (monthPay <= 0) ? 0.0 : (topJob.pay / monthPay) * 100.0;

    cards.add(
      InsightCardModel(
        id: "top_job_share",
        severity: InsightSeverity.info,
        icon: Icons.trending_up,
        iconBg: _infoBg(),
        iconColor: _infoFg(),
        title: "$topName drove ${_pct(share)} of income",
        subtitle: "${_money(topJob.pay)} • ${topJob.hours.toStringAsFixed(0)}h",
        score: 90,
      ),
    );
  }

  // Base 3) Consistency (ShiftMonth always available)
  cards.add(
    InsightCardModel(
      id: "consistency",
      severity: InsightSeverity.info,
      icon: Icons.calendar_month_outlined,
      iconBg: _infoBg(),
      iconColor: _infoFg(),
      title: "You worked $daysWorked days • $shiftCount shifts",
      subtitle: "Avg shift ${avgShiftHours.toStringAsFixed(1)}h • Longest streak $streak days",
      score: 85,
    ),
  );

  // Base 4) Best vs Weak (week-based if possible, else day-based)
  if (weeks.length >= 2) {
    _WeekAgg best = weeks.first;
    _WeekAgg worst = weeks.first;
    for (final w in weeks) {
      if (w.pay > best.pay) best = w;
      if (w.pay < worst.pay) worst = w;
    }

    cards.add(
      InsightCardModel(
        id: "best_weak_week",
        severity: (worst.pay <= 0 && monthPay > 0) ? InsightSeverity.warn : InsightSeverity.info,
        icon: Icons.stacked_line_chart,
        iconBg: (worst.pay <= 0 && monthPay > 0) ? _warnBg() : _infoBg(),
        iconColor: (worst.pay <= 0 && monthPay > 0) ? _warnFg() : _infoFg(),
        title: "Best week: ${_rangeLabel(best.start, best.end)} (${_money(best.pay)})",
        subtitle: "Weakest: ${_rangeLabel(worst.start, worst.end)} (${_money(worst.pay)})",
        score: 80,
      ),
    );
  } else {
    // fallback to best/weak day using ShiftMonth totals
    if (workedDays.isNotEmpty) {
      var best = workedDays.first;
      var worst = workedDays.first;
      for (final d in workedDays) {
        if (d.dayIncome > best.dayIncome) best = d;
        if (d.dayIncome < worst.dayIncome) worst = d;
      }

      cards.add(
        InsightCardModel(
          id: "best_weak_day",
          severity: (worst.dayIncome <= 0 && monthPay > 0) ? InsightSeverity.warn : InsightSeverity.info,
          icon: Icons.bar_chart_outlined,
          iconBg: (worst.dayIncome <= 0 && monthPay > 0) ? _warnBg() : _infoBg(),
          iconColor: (worst.dayIncome <= 0 && monthPay > 0) ? _warnFg() : _infoFg(),
          title: "Best day: ${_md(best.date)} (${_money(best.dayIncome)})",
          subtitle: "Weakest: ${_md(worst.date)} (${_money(worst.dayIncome)})",
          score: 80,
        ),
      );
    } else {
      // still keep base 4 even if empty
      cards.add(
        InsightCardModel(
          id: "no_days_logged",
          severity: InsightSeverity.info,
          icon: Icons.edit_calendar_outlined,
          iconBg: _infoBg(),
          iconColor: _infoFg(),
          title: "Log shifts to unlock patterns",
          subtitle: "Once you have a few shifts, you’ll see best weeks + trends.",
          score: 80,
        ),
      );
    }
  }

  // ------------------------------------
  // ADD-ONS (ranked, append until max 8)
  // ------------------------------------
  final addOns = <InsightCardModel>[];

  // Add-on A) Projection (current month only, require at least day 3)
  if (isCurrentMonth) {
    final dim = _daysInMonth(anchor);
    final day = t.day.clamp(1, dim);
    if (day >= 3 && monthPay > 0) {
      final projected = (monthPay / day) * dim;
      final gap = projected - monthPay;

      // score higher when projection materially differs from current
      final sc = _clampScore(60 + (gap.abs() / 200.0) * 10.0);
      addOns.add(
        InsightCardModel(
          id: "projection_pace",
          severity: InsightSeverity.info,
          icon: Icons.timeline_outlined,
          iconBg: _infoBg(),
          iconColor: _infoFg(),
          title: "On pace for ${_money(projected)}",
          subtitle: "So far: ${_money(monthPay)} in $day days",
          score: sc.clamp(60, 95),
        ),
      );
    }
  }

  // Add-on A2) Goal pace + behind/ahead (current month only)
  final g = (s.monthlyIncomeGoal ?? 0).toDouble();
  if (isCurrentMonth && g > 0) {
    final dim = _daysInMonth(anchor);
    final day = t.day.clamp(1, dim);
    final expectedSoFar = (g * day) / dim;
    final diff = monthPay - expectedSoFar;

    if (day >= 3) {
      final behind = diff < 0;
      final abs = diff.abs();
      final sc = _clampScore(70 + (abs / max(250.0, g * 0.05)) * 20.0);

      addOns.add(
        InsightCardModel(
          id: behind ? "goal_behind_pace" : "goal_ahead_pace",
          severity: behind ? InsightSeverity.warn : InsightSeverity.good,
          icon: behind ? Icons.error_outline : Icons.check_circle_outline,
          iconBg: behind ? _warnBg() : _goodBg(),
          iconColor: behind ? _warnFg() : _goodFg(),
          title: behind ? "Behind goal pace by ${_money(abs)}" : "Ahead of goal pace by ${_money(abs)}",
          subtitle: "Expected by today: ${_money(expectedSoFar)} • Goal: ${_money(g)}",
          score: sc.clamp(60, 98),
        ),
      );
    }
  }

  // Add-on B) Trend vs previous month (works for any viewed month)
  if (previous != null && (previous.totals?.pay as num?)?.toDouble() != null) {
    final prevPay = (previous.totals?.pay as num?)?.toDouble() ?? 0.0;
    final prevHours = (previous.totals?.hours as num?)?.toDouble() ?? 0.0;

    if (prevPay > 0) {
      final deltaPay = monthPay - prevPay;
      final changePct = (deltaPay / prevPay) * 100.0;

      final prevRate = _safeDiv(prevPay, prevHours);
      final deltaHours = monthHours - prevHours;
      final deltaRate = monthRate - prevRate;

      final up = deltaPay >= 0;
      final absPay = deltaPay.abs();

      // score scales with magnitude
      final sc = _clampScore(55 + (absPay / max(200.0, prevPay)) * 120.0);

      addOns.add(
        InsightCardModel(
          id: "trend_vs_prev",
          severity: up ? InsightSeverity.good : InsightSeverity.warn,
          icon: up ? Icons.arrow_upward : Icons.arrow_downward,
          iconBg: up ? _goodBg() : _warnBg(),
          iconColor: up ? _goodFg() : _warnFg(),
          title: up
              ? "Up ${_money(absPay)} vs last month (${_pct(changePct.abs())})"
              : "Down ${_money(absPay)} vs last month (${_pct(changePct.abs())})",
          subtitle:
              "Hours: ${deltaHours >= 0 ? "+" : ""}${deltaHours.toStringAsFixed(0)}h • Rate: ${deltaRate >= 0 ? "+" : ""}${_money(deltaRate)}/hr",
          score: sc.clamp(40, 100),
        ),
      );
    }
  }

  // Add-on C) Job rate gap (if >=2 jobs with usable hours)
  if (s.enableRateGapInsight) {
    final rates = _jobRates(current);
    if (rates.length >= 2) {
      final best = rates.first;
      final worst = rates.last;
      final diff = best.rate - worst.rate;

      // show only if meaningful
      if (diff >= 1.5) {
        final bestName = (best.job.jobName ?? "Best job").toString();
        final worstName = (worst.job.jobName ?? "Lower job").toString();

        final sc = _clampScore(55 + diff * 12);

        addOns.add(
          InsightCardModel(
            id: "job_rate_gap",
            severity: InsightSeverity.info,
            icon: Icons.compare_arrows,
            iconBg: _infoBg(),
            iconColor: _infoFg(),
            title: "$bestName pays ~${_money(diff)}/hr more than $worstName",
            subtitle: "Based on this month’s averages.",
            score: sc.clamp(55, 90),
          ),
        );
      }
    }
  }

  // Add-on D) Anomaly/spike (only if enough shifts + week data exists)
  if (s.enableSpikeInsight && shiftCount >= s.minShiftsForPatterns && weeks.isNotEmpty) {
    // Find any job-week with weekRate > jobAvgRate * 1.35
    final jobs = current.jobs as List? ?? const [];
    double bestRatio = 0;
    dynamic bestJob;
    dynamic bestWeek;

    for (final j in jobs) {
      final jPay = (j.totals?.pay as num?)?.toDouble() ?? 0.0;
      final jHours = (j.totals?.hours as num?)?.toDouble() ?? 0.0;
      final jRate = _safeDiv(jPay, jHours);
      if (jRate <= 0) continue;

      final jWeeks = j.weeks as List? ?? const [];
      for (final w in jWeeks) {
        final h = (w.hours as num?)?.toDouble() ?? 0.0;
        final p = (w.pay as num?)?.toDouble() ?? 0.0;
        if (h <= 0 || p <= 0) continue;

        final wr = p / h;
        final ratio = wr / jRate;
        if (ratio > 1.35 && ratio > bestRatio) {
          bestRatio = ratio;
          bestJob = j;
          bestWeek = w;
        }
      }
    }

    if (bestJob != null && bestWeek != null) {
      final name = (bestJob.jobName ?? "A job").toString();
      final wStart = bestWeek.start as DateTime?;
      final wEnd = bestWeek.end as DateTime?;
      final label = (wStart != null && wEnd != null) ? _rangeLabel(wStart, wEnd) : "that week";

      final sc = _clampScore(65 + min(25.0, (bestRatio - 1.35) * 50.0));

      addOns.add(
        InsightCardModel(
          id: "anomaly_spike",
          severity: InsightSeverity.info,
          icon: Icons.star_outline,
          iconBg: _yellowBg(),
          iconColor: _yellowFg(),
          title: "Unusual high-pay week detected",
          subtitle: "$name $label • Rate was ${bestRatio.toStringAsFixed(2)}× your average",
          score: sc.clamp(65, 95),
        ),
      );
    }
  }

  // Optional: workload + OT for CURRENT MONTH ONLY
  if (isCurrentMonth) {
    final lim = (s.safeWeeklyHoursLimit ?? 0).toDouble();
    final ot = s.otThreshold;

    // Current week totals from aggregated weeks: pick the week whose [start..end] contains today
    _WeekAgg? thisWeek;
    for (final w in weeks) {
      final a = DateTime(w.start.year, w.start.month, w.start.day);
      final b = DateTime(w.end.year, w.end.month, w.end.day);
      final today = DateTime(t.year, t.month, t.day);
      if (!today.isBefore(a) && !today.isAfter(b)) {
        thisWeek = w;
        break;
      }
    }

    if (thisWeek != null) {
      if (lim > 0 && thisWeek.hours > lim) {
        final over = thisWeek.hours - lim;
        final sc = _clampScore(75 + min(20.0, over * 4));

        addOns.add(
          InsightCardModel(
            id: "weekly_hours_limit",
            severity: InsightSeverity.warn,
            icon: Icons.warning_amber_rounded,
            iconBg: _yellowBg(),
            iconColor: _yellowFg(),
            title: "This week: ${thisWeek.hours.toStringAsFixed(0)}h — above your limit ${lim.toStringAsFixed(0)}h",
            subtitle: "Consider reducing shifts or spreading hours across jobs.",
            score: sc.clamp(70, 98),
          ),
        );
      }

      if (thisWeek.hours > ot) {
        final otH = thisWeek.hours - ot;
        final sc = _clampScore(60 + min(25.0, otH * 5));

        addOns.add(
          InsightCardModel(
            id: "overtime_alert",
            severity: InsightSeverity.info,
            icon: Icons.timer_outlined,
            iconBg: _infoBg(),
            iconColor: _infoFg(),
            title: "Overtime territory this week (OT: ${otH.toStringAsFixed(1)}h)",
            subtitle: "OT pay rules vary by job — confirm your policy.",
            score: sc.clamp(60, 92),
          ),
        );
      }
    }
  }

  // Sort add-ons by score, then append until we have max 8
  addOns.sort((a, b) => b.score.compareTo(a.score));

  // De-dup by id (just in case)
  final seen = <String>{};
  final base = <InsightCardModel>[];
  for (final c in cards) {
    if (seen.add(c.id)) base.add(c);
  }

  final out = <InsightCardModel>[...base];
  for (final c in addOns) {
    if (out.length >= 8) break;
    if (seen.add(c.id)) out.add(c);
  }

  // If there’s basically no data, replace noisy cards with onboarding (keep 4 min)
  final noData = (monthPay <= 0 && shiftCount <= 0 && daysWorked <= 0);
  if (noData) {
    return [
      InsightCardModel(
        id: "onboarding_log_shifts",
        severity: InsightSeverity.info,
        icon: Icons.calendar_month_outlined,
        iconBg: _infoBg(),
        iconColor: _infoFg(),
        title: "Log 3 shifts to activate insights",
        subtitle: "Trends need a few shifts to be meaningful.",
        score: 100,
      ),
      InsightCardModel(
        id: "onboarding_add_job",
        severity: InsightSeverity.info,
        icon: Icons.work_outline,
        iconBg: _infoBg(),
        iconColor: _infoFg(),
        title: "Add your first job to unlock breakdowns",
        subtitle: "Set pay frequency for accurate weeks and totals.",
        score: 95,
      ),
      InsightCardModel(
        id: "onboarding_set_goal",
        severity: InsightSeverity.info,
        icon: Icons.flag_outlined,
        iconBg: _infoBg(),
        iconColor: _infoFg(),
        title: "Set a monthly income goal (optional)",
        subtitle: "Then you’ll get on-track / behind alerts.",
        score: 90,
      ),
      InsightCardModel(
        id: "onboarding_safe_limit",
        severity: InsightSeverity.info,
        icon: Icons.health_and_safety_outlined,
        iconBg: _infoBg(),
        iconColor: _infoFg(),
        title: "Set a safe weekly hour limit",
        subtitle: "You’ll get workload warnings automatically.",
        score: 85,
      ),
    ];
  }

  // Guarantee min 4 (should already happen)
  return out.length >= 4 ? out : out.take(4).toList();
}
