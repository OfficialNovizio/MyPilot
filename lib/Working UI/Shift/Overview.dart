import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:math';

import 'package:intl/intl.dart';

import '../Constant UI.dart';
import 'Deposit.dart';

/// =============================
///  DATA MODELS FOR INSIGHTS
/// =============================

// class JobSummary {
//   final String id;
//   final String name;
//   final double income; // period income
//   final double hours; // period hours
//   final double? effectiveHourly; // optional (after costs)
//   final double lastPeriodIncome; // for comparison
//
//   const JobSummary({
//     required this.id,
//     required this.name,
//     required this.income,
//     required this.hours,
//     this.effectiveHourly,
//     this.lastPeriodIncome = 0,
//   });
// }
//
// class WeeklySummary {
//   final DateTime start;
//   final DateTime end;
//   final double income;
//   final double hours;
//
//   const WeeklySummary({
//     required this.start,
//     required this.end,
//     required this.income,
//     required this.hours,
//   });
// }
//
// class DepositInfo {
//   final DateTime date;
//   final double amount;
//   final String jobName;
//
//   const DepositInfo({
//     required this.date,
//     required this.amount,
//     required this.jobName,
//   });
// }
//
// /// Snapshot of everything the insight engine needs for this period.
// class InsightContext {
//   final double? monthlyGoal; // null if no goal
//   final double periodIncome; // current period income
//   final double periodHours; // current period hours
//   final double lastPeriodIncome; // previous period income
//   final double projectedIncome; // projected final income this period
//   final double safeWeeklyHours; // target max hours per week
//
//   final double thisWeekHours;
//   final double lastWeekHours;
//
//   final double overtimeHours;
//   final double overtimeEarnings;
//   final double statEarnings;
//
//   final int daysOffLast7;
//   final int missingShiftDaysLast7;
//
//   final List<JobSummary> jobs;
//   final List<WeeklySummary> recentWeeks; // last N weeks (3–12)
//   final List<DepositInfo> upcomingDeposits; // next deposits
//
//   const InsightContext({
//     this.monthlyGoal,
//     required this.periodIncome,
//     required this.periodHours,
//     this.lastPeriodIncome = 0,
//     this.projectedIncome = 0,
//     this.safeWeeklyHours = 40,
//     this.thisWeekHours = 0,
//     this.lastWeekHours = 0,
//     this.overtimeHours = 0,
//     this.overtimeEarnings = 0,
//     this.statEarnings = 0,
//     this.daysOffLast7 = 0,
//     this.missingShiftDaysLast7 = 0,
//     this.jobs = const [],
//     this.recentWeeks = const [],
//     this.upcomingDeposits = const [],
//   });
// }
//
// /// =============================
// ///  RULE + ENGINE CORE
// /// =============================
//
// typedef ConditionFn = bool Function(InsightContext ctx);
// typedef TextFn = String Function(InsightContext ctx);
//
// class InsightRule {
//   final String id;
//   final String category;
//   final int priority; // 1–5 (5 = most important)
//   final bool isWarning;
//   final ConditionFn canShow;
//   final TextFn build;
//
//   InsightRule({
//     required this.id,
//     required this.category,
//     required this.priority,
//     required this.isWarning,
//     required this.canShow,
//     required this.build,
//   });
// }
//
// class _ScoredRule {
//   final InsightRule rule;
//   final double score;
//
//   _ScoredRule(this.rule, this.score);
// }
//
// class InsightEngine {
//   final Map<String, DateTime> _lastShown = {};
//   final List<InsightRule> _rules;
//   final Duration warningCooldown;
//   final Duration normalCooldown;
//
//   InsightEngine({
//     this.warningCooldown = const Duration(days: 2),
//     this.normalCooldown = const Duration(hours: 12),
//   }) : _rules = _buildRules();
//
//   /// Main entry: returns up to [maxItems] insight texts.
//   List<String> generate(InsightContext ctx, {int maxItems = 3}) {
//     final now = DateTime.now();
//     final candidates = <_ScoredRule>[];
//
//     for (final r in _rules) {
//       if (!r.canShow(ctx)) continue;
//
//       final last = _lastShown[r.id];
//       if (last != null) {
//         final cd = r.isWarning ? warningCooldown : normalCooldown;
//         if (now.difference(last) < cd) continue;
//       }
//
//       final noveltyHours = last == null ? 9999.0 : now.difference(last).inHours.toDouble();
//       final score = r.priority * 10000 + noveltyHours;
//       candidates.add(_ScoredRule(r, score));
//     }
//
//     candidates.sort((a, b) => b.score.compareTo(a.score));
//     final selected = candidates.take(maxItems).map((c) => c.rule).toList();
//
//     for (final r in selected) {
//       _lastShown[r.id] = now;
//     }
//
//     return selected.map((r) => r.build(ctx)).toList();
//   }
// }
//
// /// =============================
// ///  RULE DEFINITIONS (~19 rules)
// /// =============================
//
// List<InsightRule> _buildRules() {
//   return [
//     // ---------- GOAL / PROJECTION ----------
//     InsightRule(
//       id: 'goal_progress_good',
//       category: 'goal',
//       priority: 5,
//       isWarning: false,
//       canShow: (ctx) {
//         final g = ctx.monthlyGoal;
//         if (g == null || g <= 0) return false;
//         final progress = ctx.periodIncome / g;
//         return progress >= 0.7 && progress <= 1.1;
//       },
//       build: (ctx) {
//         final g = ctx.monthlyGoal!;
//         final progressPct = _pct(ctx.periodIncome, g);
//         return "You’ve reached ${progressPct.toStringAsFixed(0)}% of your monthly income goal.";
//       },
//     ),
//
//     InsightRule(
//       id: 'goal_behind',
//       category: 'goal',
//       priority: 5,
//       isWarning: true,
//       canShow: (ctx) {
//         final g = ctx.monthlyGoal;
//         if (g == null || g <= 0) return false;
//         if (ctx.projectedIncome <= 0) return false;
//         return ctx.projectedIncome < g * 0.9; // clearly behind
//       },
//       build: (ctx) {
//         final g = ctx.monthlyGoal!;
//         final diff = max(0.0, g - ctx.projectedIncome);
//         return "You’re about \$${diff.round()} behind your monthly goal at this pace.";
//       },
//     ),
//
//     InsightRule(
//       id: 'goal_ahead',
//       category: 'goal',
//       priority: 4,
//       isWarning: false,
//       canShow: (ctx) {
//         final g = ctx.monthlyGoal;
//         if (g == null || g <= 0) return false;
//         if (ctx.projectedIncome <= 0) return false;
//         return ctx.projectedIncome > g * 1.05; // clearly above
//       },
//       build: (ctx) {
//         final g = ctx.monthlyGoal!;
//         final diff = max(0.0, ctx.projectedIncome - g);
//         return "You’re on track to finish about \$${diff.round()} above your income goal.";
//       },
//     ),
//
//     InsightRule(
//       id: 'suggest_set_goal',
//       category: 'goal',
//       priority: 3,
//       isWarning: false,
//       canShow: (ctx) => ctx.monthlyGoal == null,
//       build: (ctx) => "Set a monthly income goal to track your progress more clearly.",
//     ),
//
//     // ---------- PERIOD TRENDS ----------
//     InsightRule(
//       id: 'income_up_vs_last',
//       category: 'trend',
//       priority: 4,
//       isWarning: false,
//       canShow: (ctx) => ctx.lastPeriodIncome > 0 && ctx.periodIncome > ctx.lastPeriodIncome * 1.05,
//       build: (ctx) {
//         final change = _pctChange(ctx.periodIncome, ctx.lastPeriodIncome);
//         return "Your income is up ${change.toStringAsFixed(0)}% compared to the previous period.";
//       },
//     ),
//
//     InsightRule(
//       id: 'income_down_vs_last',
//       category: 'trend',
//       priority: 4,
//       isWarning: true,
//       canShow: (ctx) => ctx.lastPeriodIncome > 0 && ctx.periodIncome < ctx.lastPeriodIncome * 0.95,
//       build: (ctx) {
//         final change = _pctChange(ctx.periodIncome, ctx.lastPeriodIncome).abs().toStringAsFixed(0);
//         return "Your income is down $change% compared to the previous period.";
//       },
//     ),
//
//     // ---------- HOURS / BURNOUT ----------
//     InsightRule(
//       id: 'week_over_safe_hours',
//       category: 'hours',
//       priority: 5,
//       isWarning: true,
//       canShow: (ctx) => ctx.thisWeekHours > 0 && ctx.thisWeekHours > ctx.safeWeeklyHours,
//       build: (ctx) {
//         final extra = ctx.thisWeekHours - ctx.safeWeeklyHours;
//         return "You worked ${ctx.thisWeekHours.toStringAsFixed(0)} h this week — about ${extra.toStringAsFixed(0)} h above your safe limit of ${ctx.safeWeeklyHours.toStringAsFixed(0)} h.";
//       },
//     ),
//
//     InsightRule(
//       id: 'no_days_off',
//       category: 'hours',
//       priority: 4,
//       isWarning: true,
//       canShow: (ctx) => ctx.daysOffLast7 == 0 && ctx.thisWeekHours > 0,
//       build: (ctx) => "You’ve had no full days off in the last 7 days — consider scheduling a rest day.",
//     ),
//
//     InsightRule(
//       id: 'few_days_off',
//       category: 'hours',
//       priority: 3,
//       isWarning: false,
//       canShow: (ctx) => ctx.daysOffLast7 == 1 && ctx.thisWeekHours >= ctx.safeWeeklyHours,
//       build: (ctx) => "You only took one full day off in the last week while working heavy hours.",
//     ),
//
//     // ---------- OVERTIME / STAT ----------
//     InsightRule(
//       id: 'overtime_earnings_positive',
//       category: 'ot',
//       priority: 4,
//       isWarning: false,
//       canShow: (ctx) => ctx.overtimeHours > 0 && ctx.overtimeEarnings > 0,
//       build: (ctx) {
//         return "Overtime earned you an extra \$${ctx.overtimeEarnings.round()} this period.";
//       },
//     ),
//
//     InsightRule(
//       id: 'stat_earnings_positive',
//       category: 'stat',
//       priority: 3,
//       isWarning: false,
//       canShow: (ctx) => ctx.statEarnings > 0,
//       build: (ctx) => "Stat holiday shifts added about "
//           "\$${ctx.statEarnings.round()} to your income this period.",
//     ),
//
//     // ---------- JOB COMPARISON ----------
//     InsightRule(
//       id: 'best_hourly_job',
//       category: 'jobs',
//       priority: 4,
//       isWarning: false,
//       canShow: (ctx) => ctx.jobs.length >= 2,
//       build: (ctx) {
//         final jobs = ctx.jobs;
//         final best = _maxBy<JobSummary>(
//           jobs,
//           (j) => j.effectiveHourly ?? _safeDiv(j.income, j.hours),
//         )!;
//         final worst = _minBy<JobSummary>(
//           jobs,
//           (j) => j.effectiveHourly ?? _safeDiv(j.income, j.hours),
//         )!;
//         final bestRate = best.effectiveHourly ?? _safeDiv(best.income, best.hours);
//         final worstRate = worst.effectiveHourly ?? _safeDiv(worst.income, worst.hours);
//         final diff = bestRate - worstRate;
//         if (diff < 1) {
//           return "${best.name} currently has the highest hourly pay among your jobs.";
//         }
//         return "${best.name} pays about \$${diff.toStringAsFixed(2)} more per hour than ${worst.name} this period.";
//       },
//     ),
//
//     InsightRule(
//       id: 'job_income_vs_hours_share',
//       category: 'jobs',
//       priority: 3,
//       isWarning: false,
//       canShow: (ctx) => ctx.jobs.length >= 2 && ctx.periodIncome > 0,
//       build: (ctx) {
//         final totalIncome = ctx.jobs.fold<double>(0, (s, j) => s + j.income).clamp(0, double.infinity);
//         final totalHours = ctx.jobs.fold<double>(0, (s, j) => s + j.hours).clamp(0, double.infinity);
//         if (totalIncome <= 0 || totalHours <= 0) {
//           return "You’re working multiple jobs this period.";
//         }
//
//         JobSummary? worstEfficiency;
//         double worstGap = 0;
//
//         for (final j in ctx.jobs) {
//           final shareHours = _pct(j.hours, totalHours);
//           final shareIncome = _pct(j.income, totalIncome);
//           final gap = shareHours - shareIncome;
//           if (gap > worstGap && shareHours > 15) {
//             worstGap = gap;
//             worstEfficiency = j;
//           }
//         }
//
//         if (worstEfficiency == null || worstGap < 10) {
//           return "Your hours and income are fairly balanced across your jobs.";
//         }
//
//         return "${worstEfficiency.name} takes a big share of your hours but gives a smaller share of your income — watch its efficiency.";
//       },
//     ),
//
//     InsightRule(
//       id: 'job_with_most_ot',
//       category: 'jobs',
//       priority: 2,
//       isWarning: false,
//       canShow: (ctx) => ctx.jobs.length >= 1 && ctx.overtimeHours > 0,
//       build: (ctx) {
//         // This assumes you later extend JobSummary with OT if you want.
//         return "Most of your overtime this period comes from the same job — consider if those extra hours are worth it.";
//       },
//     ),
//
//     // ---------- WEEKS / EXTREMES ----------
//     InsightRule(
//       id: 'best_week_income',
//       category: 'weeks',
//       priority: 3,
//       isWarning: false,
//       canShow: (ctx) => ctx.recentWeeks.length >= 2,
//       build: (ctx) {
//         final bestWeek = _maxBy<WeeklySummary>(ctx.recentWeeks, (w) => w.income)!;
//         final fmt = _formatWeek(bestWeek);
//         return "Your highest-earning week recently was $fmt at about \$${bestWeek.income.round()}.";
//       },
//     ),
//
//     InsightRule(
//       id: 'biggest_hours_week',
//       category: 'weeks',
//       priority: 2,
//       isWarning: false,
//       canShow: (ctx) => ctx.recentWeeks.length >= 2 && ctx.recentWeeks.any((w) => w.hours > ctx.safeWeeklyHours),
//       build: (ctx) {
//         final busyWeek = _maxBy<WeeklySummary>(ctx.recentWeeks, (w) => w.hours)!;
//         final fmt = _formatWeek(busyWeek);
//         return "Your heaviest week recently was $fmt with ${busyWeek.hours.toStringAsFixed(0)} hours worked.";
//       },
//     ),
//
//     // ---------- DEPOSITS ----------
//     InsightRule(
//       id: 'upcoming_deposits_summary',
//       category: 'deposits',
//       priority: 3,
//       isWarning: false,
//       canShow: (ctx) => ctx.upcomingDeposits.isNotEmpty,
//       build: (ctx) {
//         final total = ctx.upcomingDeposits.fold<double>(0, (s, d) => s + d.amount).round();
//         final count = ctx.upcomingDeposits.length;
//         return "You have $count upcoming deposit${count > 1 ? "s" : ""} totaling about \$${total}.";
//       },
//     ),
//
//     InsightRule(
//       id: 'big_deposit_soon',
//       category: 'deposits',
//       priority: 4,
//       isWarning: false,
//       canShow: (ctx) {
//         if (ctx.upcomingDeposits.isEmpty) return false;
//         final now = DateTime.now();
//         final soon = ctx.upcomingDeposits.where((d) => d.date.difference(now).inDays >= 0 && d.date.difference(now).inDays <= 3).toList();
//         if (soon.isEmpty) return false;
//         final maxDep = _maxBy<DepositInfo>(soon, (d) => d.amount)!;
//         return maxDep.amount >= ctx.periodIncome * 0.1; // reasonably big
//       },
//       build: (ctx) {
//         final now = DateTime.now();
//         final soon = ctx.upcomingDeposits.where((d) => d.date.difference(now).inDays >= 0 && d.date.difference(now).inDays <= 3).toList();
//         final big = _maxBy<DepositInfo>(soon, (d) => d.amount)!;
//         final days = big.date.difference(now).inDays;
//         final when = days <= 0 ? "today" : "in $days day${days > 1 ? "s" : ""}";
//         return "You have a \$${big.amount.round()} deposit from ${big.jobName} coming $when.";
//       },
//     ),
//
//     // ---------- DATA QUALITY ----------
//     InsightRule(
//       id: 'missing_shift_days',
//       category: 'data',
//       priority: 2,
//       isWarning: false,
//       canShow: (ctx) => ctx.missingShiftDaysLast7 >= 2,
//       build: (ctx) =>
//           "There are about ${ctx.missingShiftDaysLast7} days in the last week without shifts logged — update them to keep stats accurate.",
//     ),
//   ];
// }
//
// /// =============================
// ///  HELPER FUNCTIONS
// /// =============================
//
// double _safeDiv(double a, double b) {
//   if (b == 0) return 0;
//   return a / b;
// }
//
// double _pct(double part, double total) {
//   if (total == 0) return 0;
//   return (part / total) * 100;
// }
//
// double _pctChange(double current, double previous) {
//   if (previous == 0) return 0;
//   return ((current - previous) / previous) * 100;
// }
//
// T? _maxBy<T>(Iterable<T> list, double Function(T) selector) {
//   T? best;
//   double bestScore = double.negativeInfinity;
//   for (final item in list) {
//     final score = selector(item);
//     if (score > bestScore) {
//       bestScore = score;
//       best = item;
//     }
//   }
//   return best;
// }
//
// T? _minBy<T>(Iterable<T> list, double Function(T) selector) {
//   T? best;
//   double bestScore = double.infinity;
//   for (final item in list) {
//     final score = selector(item);
//     if (score < bestScore) {
//       bestScore = score;
//       best = item;
//     }
//   }
//   return best;
// }
//
// String _formatWeek(WeeklySummary w) {
//   // very simple "Apr 3–9" style; you can replace with intl if you want
//   final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
//   final m = months[w.start.month - 1];
//   return "$m ${w.start.day}–${w.end.day}";
// }

DateTime selectedMonth = DateTime.now();
int selectedRange = 1; // 1 = 1M, 3 = 3M

String formatMonth(DateTime d) {
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return '${months[d.month - 1]} ${d.year}';
}

void goToPreviousMonth() {
  // setState(() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
  // });
}

void goToNextMonth() {
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
  if (!nextMonth.isAfter(currentMonth)) {
    // setState(() {
      selectedMonth = nextMonth;
    // });
  }
}

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============= TOP: MONTH PILL + RANGE TOGGLE ============
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: height * .03, bottom: height * .02),
              child: MonthPill(
                label: formatMonth(selectedMonth),
                onPrev: goToPreviousMonth,
                onNext: goToNextMonth,
                canGoNext: !DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                  1,
                ).isAfter(DateTime(DateTime.now().year, DateTime.now().month, 1)),
              ),
            ),
          ),

          // ============= OVERVIEW TITLE ============
          textWidget(
              text: "${DateFormat('MMMM').format(selectedMonth)} - Overview",
              fontSize: .028,
              fontWeight: FontWeight.w700,
              color: ProjectColors.whiteColor),

          SizedBox(height: height * .015),

          // ============= ESTIMATED INCOME CARD ============
          const _EstimatedIncomeCard(),

          SizedBox(height: height * .025),

          // ============= INSIGHTS ============
          textWidget(
            text: "Insights",
            fontSize: .03,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .01),
          const _InsightsCard(),

          SizedBox(height: height * .025),

          // ============= WEEKLY BREAKDOWN ============
          textWidget(
            text: "Weekly Breakdown",
            fontSize: .03,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .01),
          const _WeeklyBreakdownList(),

          SizedBox(height: height * .025),
        ],
      ),
    );
  }
}

// ===================================================================
//                         TOP CONTROLS
// ===================================================================

class MonthPill extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const MonthPill({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProjectColors.pureBlackColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPrev,
            child: Icon(
              Icons.chevron_left,
              size: height * .028,
              color: ProjectColors.whiteColor,
            ),
          ),
          SizedBox(width: width * .01),
          textWidget(
            text: label,
            fontSize: .018,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(width: width * .01),
          GestureDetector(
            onTap: canGoNext ? onNext : null,
            child: Icon(
              Icons.chevron_right,
              size: height * .028,
              color: canGoNext ? ProjectColors.whiteColor : ProjectColors.whiteColor.withOpacity(.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final int selected; // 1M or 3M
  final ValueChanged<int> onChanged;

  const _RangeToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _rangeItem("1M", 1),
        SizedBox(width: width * .015),
        _rangeItem("3M", 3),
      ],
    );
  }

  Widget _rangeItem(String text, int value) {
    final isActive = selected == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: textWidget(
        text: text,
        fontSize: .018,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        color: isActive ? ProjectColors.pureBlackColor : ProjectColors.blackColor.withOpacity(.6),
      ),
    );
  }
}

// ===================================================================
//                         ESTIMATED INCOME CARD
// ===================================================================

class _EstimatedIncomeCard extends StatelessWidget {
  const _EstimatedIncomeCard();

  @override
  Widget build(BuildContext context) {
    const double progress = 0.624; // 62%

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: width * .04,
        vertical: height * .018,
      ),
      decoration: BoxDecoration(
        color: ProjectColors.pureBlackColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top line: title + %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textWidget(
                text: "Estimated Income",
                fontSize: .018,
                fontWeight: FontWeight.w500,
                color: ProjectColors.whiteColor,
              ),
              textWidget(
                text: "62%",
                fontSize: .018,
                fontWeight: FontWeight.w600,
                color: ProjectColors.whiteColor,
              ),
            ],
          ),
          SizedBox(height: height * .012),

          // Main amount
          textWidget(
            text: "\$3,120",
            fontSize: .035,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .012),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: height * .008,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    color: ProjectColors.greenColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: height * .01),

          // Goal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textWidget(
                text: "Goal: \$5,000",
                fontSize: .016,
                color: ProjectColors.whiteColor.withOpacity(.7),
              ),
              textWidget(
                text: "Total hours 30",
                fontSize: .016,
                color: ProjectColors.whiteColor.withOpacity(.7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================================================================
//                              INSIGHTS
// ===================================================================

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .04,
        vertical: height * .014,
      ),
      decoration: BoxDecoration(
        color: ProjectColors.pureBlackColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: const [
          _InsightRow(
            icon: Icons.check_circle,
            iconColor: Color(0xff22c55e),
            bgColor: Color(0x1f22c55e),
            text: "You’ve reached 72% of your monthly income goal",
          ),
          SizedBox(height: 8),
          _InsightRow(
            icon: Icons.error_outline,
            iconColor: Color(0xfff97316),
            bgColor: Color(0x1ff97316),
            text: "You worked 51 hours this week – that’s above your safe limit of 45 h",
          ),
          SizedBox(height: 8),
          _InsightRow(
            icon: Icons.star,
            iconColor: Color(0xffeab308),
            bgColor: Color(0x1feab308),
            text: "Stat holiday shifts added \$95 to your income this month",
          ),
          SizedBox(height: 8),
          _InsightRow(
            icon: Icons.lightbulb_outline,
            iconColor: Color(0xfffacc15),
            bgColor: Color(0x1ffacc15),
            text: "Starbucks pays \$4.20 more per hour than Superstore on average",
          ),
          SizedBox(height: 8),
          _InsightRow(
            icon: Icons.savings_outlined,
            iconColor: Color(0xfff59e0b),
            bgColor: Color(0x1ff59e0b),
            text: "Shifting 5 hours from DoorDash to Starbucks would add about \$70/month",
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String text;

  const _InsightRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: height * .032,
          height: height * .032,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: height * .02,
            color: iconColor,
          ),
        ),
        SizedBox(width: width * .03),
        Expanded(
          child: textWidget(
            text: text,
            fontSize: .018,
            fontWeight: FontWeight.w500,
            color: ProjectColors.whiteColor,
          ),
        ),
      ],
    );
  }
}

// ===================================================================
//                         WEEKLY BREAKDOWN
// ===================================================================

class _WeeklyBreakdownList extends StatelessWidget {
  const _WeeklyBreakdownList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _JobWeeklyCard(
          color: Color(0xff00704A),
          title: "Starbucks",
          income: "\$920",
          hours: "48 h",
        ),
        SizedBox(height: height * .01),
        const _JobWeeklyCard(
          color: Color(0xffE41E26),
          title: "DoorDash",
          income: "\$720",
          hours: "36 h",
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * .04,
            vertical: height * .01,
          ),
          child: Divider(color: ProjectColors.whiteColor.withOpacity(0.5)),
        ),
      ],
    );
  }
}

class _JobWeeklyCard extends StatelessWidget {
  final Color color;
  final String title;
  final String income;
  final String hours;

  const _JobWeeklyCard({
    required this.color,
    required this.title,
    required this.income,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: height * .03,
            backgroundColor: color,
            child: textWidget(
              text: title.characters.first,
              fontSize: .03,
              color: ProjectColors.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: width * .03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(
                  text: title,
                  fontSize: .02,
                  fontWeight: FontWeight.w600,
                  color: ProjectColors.whiteColor,
                ),
                SizedBox(height: height * .003),
                textWidget(
                  text: "Week 1",
                  fontSize: .018,
                  color: ProjectColors.whiteColor.withOpacity(.8),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              textWidget(
                text: income,
                fontSize: .018,
                fontWeight: FontWeight.w600,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(height: height * .004),
              textWidget(
                text: hours,
                fontSize: .018,
                fontWeight: FontWeight.w600,
                color: ProjectColors.whiteColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================================================================
//                         UPCOMING DEPOSITS
// ===================================================================

class _UpcomingDepositsCard extends StatelessWidget {
  const _UpcomingDepositsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .04,
        vertical: height * .014,
      ),
      decoration: BoxDecoration(
        color: ProjectColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          textWidget(
            text: "April 28",
            fontSize: .018,
            fontWeight: FontWeight.w500,
          ),
          textWidget(
            text: "\$1,200",
            fontSize: .02,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

// class OverviewTab extends StatelessWidget {
//   const OverviewTab();
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(height: height * .05),
//         OverviewControls(),
//         SizedBox(height: height * .02),
//         // CompareMiniCard(period: shift.period!.value, metric: shift.metric!.value, jobs: selectedJobs),
//
//         SizedBox(height: height * .01),
//         CompareTab(),
//         SizedBox(height: height * .01),
//         // Stable donut
//         // PayComposition(period: shift.period!.value, jobs: selectedJobs),
//         SizedBox(height: height * .01),
//         // InsightsCard(period: shift.period!.value, jobs: selectedJobs),
//       ],
//     );
//   }
// }
//
// class CompareTab extends StatelessWidget {
//   const CompareTab();
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       // shift.initJobs(app.jobs.map((e) => e.id!));
//       // final jobs = app.jobs.where((j) => shift.jobs.contains(j.id)).toList();
//
//       final labels = <String>[];
//       final series = <String, List<double>>{}; // jobId -> points
//
//       if (shift.period!.value == 'monthly') {
//         for (int i = 7; i >= 0; i--) {
//           final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
//           labels.add('${m.month}/${(m.year % 100).toString().padLeft(2, '0')}');
//         }
//         // for (final j in jobs) {
//         //   series[j.id!] = [];
//         //   for (int i = 7; i >= 0; i--) {
//         //     final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
//         //     final sum = app.monthNetSummary(m)['perJob'][j.id] as Map;
//         //     series[j.id]!.add(pickMetric(sum, shift.metric!.value));
//         //   }
//         // }
//       } else {
//         // for (final j in jobs) {
//         //   final ps = app.periodsAround(j, back: 8, forward: 0).reversed.toList();
//         //   series[j.id!] = ps.map((p) => metricFromPeriod(app, j, p, shift.metric!.value)).toList();
//         //   if (labels.length < ps.length) {
//         //     labels
//         //       ..clear()
//         //       ..addAll(ps.map((p) => md(p.deposit)));
//         //   }
//         // }
//       }
//
//       // final colors = jobs.map((j) => app.jobColor(j.colorHex!)).toList();
//
//       return CustomCard(
//         title: 'Compare (${periodLabel(shift.period!.value)}) — ${metricTitle(shift.metric!.value)}',
//         color: ProjectColors.whiteColor,
//         child: SizedBox(
//           height: 240,
//           child: BarChart(
//             BarChartData(
//               gridData: FlGridData(show: true, horizontalInterval: 20),
//               titlesData: FlTitlesData(
//                 leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
//                 rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                   showTitles: true,
//                   reservedSize: 32,
//                   getTitlesWidget: (v, _) {
//                     final i = v.toInt();
//                     if (i < 0 || i >= labels.length) return const SizedBox.shrink();
//                     return Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Text(labels[i], style: const TextStyle(fontSize: 10)),
//                     );
//                   },
//                 )),
//               ),
//               borderData: FlBorderData(show: false),
//               barGroups: List.generate(labels.length, (i) {
//                 final rods = <BarChartRodData>[];
//                 // for (int j = 0; j < jobs.length; j++) {
//                 //   final jid = jobs[j].id;
//                 //   final y = i < (series[jid]?.length ?? 0) ? series[jid]![i] : 0.0;
//                 //   rods.add(BarChartRodData(toY: y, color: colors[j], width: 10));
//                 // }
//                 return BarChartGroupData(x: i, barRods: rods, barsSpace: 6);
//               }),
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }
//
// class OverviewControls extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     Widget chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
//           label: textWidget(text: label, fontSize: .015),
//           selected: sel,
//           onSelected: (_) => onTap(),
//           materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//           backgroundColor: ProjectColors.whiteColor,
//           selectedColor: ProjectColors.greenColor,
//           avatarBorder: Border.all(color: Colors.transparent),
//         );
//
//     return Obx(() => Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Wrap(spacing: 8, runSpacing: 8, children: [
//               chip('Weekly', shift.period!.value == 'weekly', () => shift.period!.value = 'weekly'),
//               chip('Biweekly', shift.period!.value == 'biweekly', () => shift.period!.value = 'biweekly'),
//               chip('Monthly', shift.period!.value == 'monthly', () => shift.period!.value = 'monthly'),
//               chip('Net', shift.metric!.value == 'net', () => shift.metric!.value = 'net'),
//               chip('Gross', shift.metric!.value == 'gross', () => shift.metric!.value = 'gross'),
//               chip('Hours', shift.metric!.value == 'hours', () => shift.metric!.value = 'hours'),
//               chip('OT', shift.metric!.value == 'ot', () => shift.metric!.value = 'ot'),
//             ]),
//             SizedBox(height: height * .02),
//             Wrap(spacing: 8, children: [
//               chip('vs Last', shift.baseline!.value == 'last', () => shift.baseline!.value = 'last'),
//               chip('vs Avg(3)', shift.baseline!.value == 'avg', () => shift.baseline!.value = 'avg'),
//             ]),
//             SizedBox(height: height * .02),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: [
//                 // for (final j in app.jobs)
//                 // FilterChip(
//                 //   label: textWidget(text: j.name, fontSize: .015),
//                 //   selectedColor: ProjectColors.greenColor,
//                 //   backgroundColor: ProjectColors.greenColor.withOpacity(0.6),
//                 //   selected: shift.jobs.contains(j.id),
//                 //   onSelected: (_) {
//                 //     if (shift.jobs.contains(j.id)) {
//                 //       shift.jobs.remove(j.id);
//                 //     } else {
//                 //       shift.jobs.add(j.id);
//                 //     }
//                 //   },
//                 //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 // ),
//                 // if (app.jobs.isNotEmpty)
//                 // FilterChip(
//                 //   label: textWidget(text: 'Both', fontSize: .015),
//                 //   selectedColor: ProjectColors.greenColor,
//                 //   backgroundColor: ProjectColors.greenColor.withOpacity(0.6),
//                 //   selected: shift.jobs.length == app.jobs.length,
//                 //   onSelected: (_) {
//                 //     shift.jobs
//                 //       ..clear()
//                 //       ..addAll(app.jobs.map((e) => e.id));
//                 //   },
//                 // ),
//               ],
//             ),
//           ],
//         ));
//   }
// }
//
// class CompareMiniCard extends StatelessWidget {
//   final String period;
//   final String metric;
//   final List<Job> jobs;
//   const CompareMiniCard({required this.period, required this.metric, required this.jobs});
//
//   @override
//   Widget build(BuildContext context) {
//     double current = 0, base = 0;
//
//     for (final j in jobs) {
//       if (period == 'monthly') {
//         final now = DateTime.now();
//         final thisM = app.monthNetSummary(DateTime(now.year, now.month, 1));
//         final prevM = app.monthNetSummary(DateTime(now.year, now.month - 1, 1));
//         // current += pickMetric(thisM['perJob'][j.id] as Map, metric);
//         // base += pickMetric(prevM['perJob'][j.id] as Map, metric);
//       } else {
//         // use pay periods
//         final nowPs = app.periodsAround(j, back: 0, forward: 0);
//         final prevPs = app.periodsAround(j, back: 1, forward: 0);
//         if (nowPs.isNotEmpty) current += metricFromPeriod(app, j, nowPs.first, metric);
//         if (prevPs.isNotEmpty) base += metricFromPeriod(app, j, prevPs.first, metric);
//       }
//     }
//
//     final diff = current - base;
//     final up = diff >= 0;
//     final color = up ? const Color(0xFF013415) : const Color(0xFFEF4444);
//
//     return CustomCard(
//       title: 'Compare — ${metricTitle(metric)}',
//       trailing: Container(
//         padding: EdgeInsets.symmetric(horizontal: height * .01, vertical: height * .01),
//         decoration: BoxDecoration(
//           color: color,
//           border: Border.all(color: color),
//           borderRadius: BorderRadius.circular(999),
//         ),
//         child: textWidget(text: '${up ? '+' : ''}${diff.toStringAsFixed(2)}', fontSize: .015, fontWeight: FontWeight.w400, color: Colors.white),
//       ),
//       child: Row(
//         children: [
//           Expanded(child: _kpi('Current', current, metric)),
//           // SizedBox(width: width * .012),
//           Expanded(child: _kpi('Last', base, metric)),
//         ],
//       ),
//     );
//   }
//
//   Widget _kpi(String label, double v, String metric) => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           textWidget(text: label, fontSize: .015, color: ProjectColors.pureBlackColor),
//           SizedBox(height: height * .005),
//           textWidget(text: fmt(metric, v), fontSize: .02, color: ProjectColors.pureBlackColor, fontWeight: FontWeight.w800),
//         ],
//       );
// }
//
// class PayComposition extends StatelessWidget {
//   final String period;
//   final List<Job> jobs;
//   const PayComposition({required this.period, required this.jobs});
//
//   @override
//   Widget build(BuildContext context) {
//     double gross = 0, net = 0, income = 0, cpp = 0, ei = 0, other = 0, post = 0;
//
//     // for (final j in jobs) {
//     //   if (period == 'monthly') {
//     //     final m = app.monthNetSummary(DateTime(DateTime.now().year, DateTime.now().month, 1));
//     //     // final row = (m['perJob'][j.id] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
//     //     gross += row['gross'] ?? row['pay'] ?? 0;
//     //     net += row['net'] ?? row['pay'] ?? 0;
//     //     income += row['incomeTax'] ?? 0;
//     //     cpp += row['cpp'] ?? 0;
//     //     ei += row['ei'] ?? 0;
//     //     other += row['other'] ?? 0;
//     //     post += row['fixed'] ?? 0;
//     //   } else {
//     //     final p = app.periodsAround(j, back: 0, forward: 0).firstOrNull;
//     //     if (p == null) continue;
//     //     gross += p.pay;
//     //     net += app.estimateNetForPeriod(j, p);
//     //     final t = app.taxFor(j.id!);
//     //     income += p.pay * (t.incomeTaxPct / 100);
//     //     cpp += p.pay * (t.cppPct / 100);
//     //     ei += p.pay * (t.eiPct / 100);
//     //     other += p.pay * (t.otherPct / 100);
//     //     post += (p.pay - (income + cpp + ei + other)).clamp(0, double.infinity) * (t.postTaxExpensePct / 100);
//     //   }
//     // }
//
//     final slices = [
//       Slice('Net', net, const Color(0xFF035D24)),
//       Slice('Income', income, const Color(0xFFEF4444)),
//       Slice('CPP', cpp, const Color(0xFF60A5FA)),
//       Slice('EI', ei, const Color(0xFFF59E0B)),
//       Slice('Other %', other, const Color(0xFF9CA3AF)),
//       Slice('Post-exp %', post, const Color(0xFF7C3AED)),
//     ].where((s) => s.value > 0.01).toList();
//
//     return CustomCard(
//       color: ProjectColors.whiteColor,
//       title: 'Pay Composition (this ${periodLabel(period)})',
//       child: Column(
//         children: [
//           SizedBox(
//             height: height * .25,
//             child: PieChart(
//               PieChartData(
//                 centerSpaceRadius: height * .06,
//                 sectionsSpace: 1,
//                 sections: [
//                   for (final s in slices) PieChartSectionData(value: s.value, color: s.color, title: '', radius: height * .06),
//                 ],
//               ),
//             ),
//           ),
//           SizedBox(height: height * .01),
//           Wrap(
//             spacing: 12,
//             runSpacing: 6,
//             children: [
//               for (final s in slices) legendDot(s.color, '${s.label} ${money(s.value)}'),
//             ],
//           ),
//           SizedBox(height: height * .01),
//           Align(
//             alignment: Alignment.centerRight,
//             child: textWidget(
//                 text: 'Effective deduction: ${gross == 0 ? '0.0' : (((gross - net) / gross) * 100).toStringAsFixed(1)}%',
//                 fontSize: .015,
//                 fontWeight: FontWeight.w400),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class InsightsCard extends StatelessWidget {
//   final String period;
//   final List<Job> jobs;
//   const InsightsCard({required this.period, required this.jobs});
//
//   @override
//   Widget build(BuildContext context) {
//     final tips = <String>[
//       'Tip: add stat days on Calendar to see premium effects in totals.',
//       'Use each job’s Tax Settings to improve net accuracy.',
//       'Projection tab estimates next period with custom hours per job.',
//     ];
//     if (jobs.isEmpty) tips.insert(0, 'No jobs selected.');
//     return CustomCard(
//       color: ProjectColors.whiteColor,
//       title: 'Insights',
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: tips.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $s'))).toList(),
//       ),
//     );
//   }
// }
