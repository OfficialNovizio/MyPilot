import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/Overview Model.dart';
import '../../Constants.dart';
import '../../Controllers.dart';

/// ---------------------------------------------------------------------------
/// INSIGHTS (GetX Controller)
/// ---------------------------------------------------------------------------

enum InsightSeverity { good, info, warn }

enum SortMetric { pay, hours }

class InsightCardModel {
  final String id;
  final InsightSeverity severity;
  final IconData icon;

  /// NOTE: This is UI-ish. If you want cleaner architecture, store only severity
  /// and let UI map it to color. But you asked to keep it strict/simple.
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
  double? monthlyIncomeGoal; // ex: 5000
  double? safeWeeklyHoursLimit; // ex: 45
  double otThreshold; // ex: 40
  bool? enableSwapSuggestion;
  bool? isNewUser; // true when user just started + no data
  int? minDataWeeks;

  InsightSettings({
    this.monthlyIncomeGoal = 2500,
    this.safeWeeklyHoursLimit = 50,
    this.otThreshold = 40,
    this.enableSwapSuggestion = true,
    this.isNewUser = false,
    this.minDataWeeks = 3,
  });

  InsightSettings copyWith({
    double? monthlyIncomeGoal,
    double? safeWeeklyHoursLimit,
    double? otThreshold,
    bool? enableSwapSuggestion,
    bool? isNewUser,
    int? minDataWeeks,
  }) {
    return InsightSettings(
      monthlyIncomeGoal: monthlyIncomeGoal ?? this.monthlyIncomeGoal,
      safeWeeklyHoursLimit: safeWeeklyHoursLimit ?? this.safeWeeklyHoursLimit,
      otThreshold: otThreshold ?? this.otThreshold,
      enableSwapSuggestion: enableSwapSuggestion ?? this.enableSwapSuggestion,
      isNewUser: isNewUser ?? this.isNewUser,
      minDataWeeks: minDataWeeks ?? this.minDataWeeks,
    );
  }
}

class OverviewInsightsController extends GetxController {
  /// You set these from your Overview screen when month changes.
  Rxn<OverviewModel>? current = Rxn<OverviewModel>();
  Rxn<OverviewModel>? previous = Rxn<OverviewModel>();
  RxList<OverviewModel> overViewShifts = RxList<OverviewModel>([]);

  /// settings can be changed from user preferences
  Rxn<InsightSettings>? settings = Rxn<InsightSettings>(InsightSettings());

  /// output list (use this directly in UI)
  final RxList<InsightCardModel> insights = <InsightCardModel>[].obs;

  /// how many to show in UI
  final RxInt maxItems = 5.obs;
  Rx<DateTime> selectedMonth = Rx<DateTime>(DateTime.now());

  /// Call this when you load month data
  void setOverviews() {
    overViewShifts.value = shift.buildCombinedOverviews();
    if (overViewShifts.isNotEmpty) {
      overViewShifts.sort((a, b) => monthName(b.month!).compareTo(monthName(a.month!)));
      current!.value = overViewShifts.first;
      // previous becomes the next item if it exists and is exactly previous month
      if (overViewShifts.length > 2) {
        final expectedPrev = DateTime(selectedMonth.value.year, selectedMonth.value.month - 1, 1);
        previous!.value = overViewShifts.firstWhereOrNull((x) => monthName(x.month!) == monthName(expectedPrev))!;
      }
      recompute();
    } else {
      // settings!.value = InsightSettings(isNewUser: true);
    }
    current!.refresh();
    previous!.refresh();
    settings!.refresh();
    // buildWeeklySortedRows();
  }

  /// Call this when you update user settings (goal, safe limit, etc.)
  void updateSettings(InsightSettings s) {
    settings!.value = s;
    recompute();
  }

  void setMaxItems(int n) {
    maxItems.value = n.clamp(1, 20);
    recompute();
  }

  /// MAIN: recompute insights list
  void recompute({DateTime? now}) {
    insights.clear();
    final items = _pickTopInsights(now: now ?? DateTime.now(), maxItems: maxItems.value);
    insights.assignAll(items);
    insights.refresh();
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

  void shiftMonth(int delta, {bool blockFuture = true}) {
    final next = DateTime(selectedMonth.value.year, selectedMonth.value.month + delta, 1);

    if (blockFuture) {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      if (next.isAfter(currentMonth)) return;
    }
    if (overViewShifts.any((t) => monthName(t.month!) == monthName(next))) {
      selectedMonth.value = next;
      selectedMonth.refresh();
      setOverviews();
    } else {
      showSnackBar("Error: No Previous Month", "You don’t have any shift records from the previous month.");
    }
  }

// usage:
  void goToPreviousMonth() => shiftMonth(-1);
  void goToNextMonth() => shiftMonth(1);

  /// -------------------------------------------------------------------------
  /// INSIGHT ENGINE (moved inside controller)
  /// -------------------------------------------------------------------------

  List<InsightCardModel> _pickTopInsights({required DateTime now, int maxItems = 5}) {
    // New user / empty data → onboarding insights only.
    final hasAnyHours = current!.value!.totals!.hours > 0.01;
    final hasJobs = current!.value!.jobs!.isNotEmpty;

    if (settings!.value!.isNewUser! || !hasJobs || !hasAnyHours) {
      return _newUserInsights(current: current!.value!).take(maxItems).toList();
    }

    final candidates = <InsightCardModel>[
      ..._goalProgress(current: current!.value!, settings: settings!.value!),
      ..._behindGoalPace(current: current!.value!, settings: settings!.value!, now: now),
      ..._weeklyWorkloadAlert(current: current!.value!, settings: settings!.value!, now: now),
      ..._overtimeAlert(current: current!.value!, settings: settings!.value!, now: now),
      ..._highPaySpikes(current: current!.value!),
      ..._bestEarner(current: current!.value!),
      ..._incomeTrend(current: current!.value!, previous: previous!.value),
      ..._payRateComparison(current: current!.value!),
      ..._swapSuggestion(current: current!.value!, settings: settings!.value!),
      // ..._nextDepositCountdown(current: current!.value!, now: now),
      ..._cashGapProxy(current: current!.value!),
    ];

    // Dedup (keep highest score)
    final unique = <String, InsightCardModel>{};
    for (final c in candidates) {
      final prevItem = unique[c.id];
      if (prevItem == null || c.score > prevItem.score) unique[c.id] = c;
    }

    final list = unique.values.toList()..sort((a, b) => b.score.compareTo(a.score));

    return list.take(maxItems).toList();
  }

  /// ---------------- Helpers ----------------

  String _money(num v) => "\$${v.toStringAsFixed(0)}";
  String _pct(num v) => "${v.toStringAsFixed(0)}%";

  int _daysBetween(DateTime a, DateTime b) {
    final aa = DateTime(a.year, a.month, a.day);
    final bb = DateTime(b.year, b.month, b.day);
    return bb.difference(aa).inDays;
  }

  bool _isInRange(DateTime x, DateTime s, DateTime e) {
    final xx = DateTime(x.year, x.month, x.day);
    final ss = DateTime(s.year, s.month, s.day);
    final ee = DateTime(e.year, e.month, e.day);
    return !xx.isBefore(ss) && !xx.isAfter(ee);
  }

  Totals _currentWeekTotals(OverviewModel current, DateTime now) {
    double h = 0, p = 0;
    bool matched = false;

    for (final j in current.jobs!) {
      final w = j.weeks.where((x) => _isInRange(now, x.start, x.end)).toList();
      if (w.isNotEmpty) {
        matched = true;
        for (final x in w) {
          h += x.hours;
          p += x.pay;
        }
      }
    }

    if (matched) return Totals(hours: h, pay: p);

    // fallback: last week row per job
    for (final j in current.jobs!) {
      if (j.weeks.isNotEmpty) {
        final last = j.weeks.last;
        h += last.hours;
        p += last.pay;
      }
    }
    return Totals(hours: h, pay: p);
  }

  double _avgRate(JobWeekly j) {
    if (j.totals.hours <= 0) return 0;
    return j.totals.pay / j.totals.hours;
  }

  /// ---------------- New user insights ----------------

  List<InsightCardModel> _newUserInsights({required OverviewModel current}) {
    return [
      InsightCardModel(
        id: "onboarding_add_job",
        severity: InsightSeverity.info,
        icon: Icons.work_outline,
        iconBg: ProjectColors.greenColor.withOpacity(.5),
        iconColor: ProjectColors.greenColor,
        title: "Add your first job to unlock breakdowns",
        subtitle: "Set pay frequency + week start for accurate weeks/deposits.",
        score: 100,
      ),
      InsightCardModel(
        id: "onboarding_log_shifts",
        severity: InsightSeverity.info,
        icon: Icons.calendar_month_outlined,
        iconBg: ProjectColors.greenColor.withOpacity(.5),
        iconColor: ProjectColors.greenColor,
        title: "Log 3 shifts to activate insights",
        subtitle: "Trends need at least a few shifts to be meaningful.",
        score: 95,
      ),
      InsightCardModel(
        id: "onboarding_set_goal",
        severity: InsightSeverity.info,
        icon: Icons.flag_outlined,
        iconBg: ProjectColors.greenColor.withOpacity(.5),
        iconColor: ProjectColors.greenColor,
        title: "Set a monthly income goal (optional)",
        subtitle: "Then you’ll get “on track / behind” alerts.",
        score: 80,
      ),
      InsightCardModel(
        id: "onboarding_safe_limit",
        severity: InsightSeverity.info,
        icon: Icons.health_and_safety_outlined,
        iconBg: ProjectColors.greenColor.withOpacity(.5),
        iconColor: ProjectColors.greenColor,
        title: "Set a safe weekly hour limit",
        subtitle: "You’ll get workload warnings automatically.",
        score: 70,
      ),
    ];
  }

  /// ---------------- Core insights ----------------

  List<InsightCardModel> _goalProgress({required OverviewModel current, required InsightSettings settings}) {
    final g = settings.monthlyIncomeGoal;
    if (g == null || g <= 0) return const [];
    final pct = (current.totals!.pay / g) * 100.0;

    return [
      InsightCardModel(
        id: "goal_progress",
        severity: pct >= 80 ? InsightSeverity.good : InsightSeverity.info,
        icon: Icons.check_circle_outline,
        iconBg: ProjectColors.greenColor.withOpacity(.3),
        iconColor: ProjectColors.greenColor,
        title: "You’ve reached ${_pct(pct)} of your monthly income goal",
        subtitle: "Goal: ${_money(g)} • Current: ${_money(current.totals!.pay)}",
        score: pct >= 90 ? 95 : 70,
      ),
    ];
  }

  List<InsightCardModel> _behindGoalPace({required OverviewModel current, required InsightSettings settings, required DateTime now}) {
    final g = settings.monthlyIncomeGoal;
    if (g == null || g <= 0) return const [];

    final daysInMonth = DateTime(current.month!.year, current.month!.month + 1, 0).day;
    final day = now.day.clamp(1, daysInMonth);
    final expectedSoFar = (g * day) / daysInMonth;

    final gap = current.totals!.pay - expectedSoFar;
    if (gap >= 0) return const [];

    return [
      InsightCardModel(
        id: "goal_behind_pace",
        severity: InsightSeverity.warn,
        icon: Icons.error_outline,
        iconBg: ProjectColors.errorColor.withOpacity(.3),
        iconColor: ProjectColors.errorColor,
        title: "You’re behind your goal pace by ${_money(gap.abs())}",
        subtitle: "Expected by today: ${_money(expectedSoFar)}",
        score: 92,
      ),
    ];
  }

  List<InsightCardModel> _weeklyWorkloadAlert({required OverviewModel current, required InsightSettings settings, required DateTime now}) {
    final lim = settings.safeWeeklyHoursLimit;
    if (lim == null || lim <= 0) return const [];

    final w = _currentWeekTotals(current, now);
    if (w.hours <= lim) return const [];

    return [
      InsightCardModel(
        id: "weekly_hours_limit",
        severity: InsightSeverity.warn,
        icon: Icons.warning_amber_rounded,
        iconBg: ProjectColors.yellowColor.withOpacity(.3),
        iconColor: ProjectColors.yellowColor,
        title: "You worked ${w.hours.toStringAsFixed(0)} hours this week — above your limit ${lim.toStringAsFixed(0)}h",
        subtitle: "Consider reducing shifts or moving workload across jobs.",
        score: 90,
      ),
    ];
  }

  List<InsightCardModel> _overtimeAlert({required OverviewModel current, required InsightSettings settings, required DateTime now}) {
    final w = _currentWeekTotals(current, now);
    if (w.hours <= settings.otThreshold) return const [];
    final ot = w.hours - settings.otThreshold;

    return [
      InsightCardModel(
        id: "overtime_alert",
        severity: InsightSeverity.info,
        icon: Icons.timer_outlined,
        iconBg: ProjectColors.greenColor.withOpacity(.3),
        iconColor: ProjectColors.greenColor,
        title: "You’re in overtime territory this week (OT: ${ot.toStringAsFixed(1)}h)",
        subtitle: "OT pay varies by job — confirm your rules.",
        score: 75,
      ),
    ];
  }

  /// “Stat premium” is NOT in your model, so we do a safe version:
  /// show only when some week has pay/hr unusually higher than month avg.
  List<InsightCardModel> _highPaySpikes({required OverviewModel current}) {
    double spikes = 0;
    for (final j in current.jobs!) {
      final r = _avgRate(j);
      for (final w in j.weeks) {
        final wr = (w.hours <= 0) ? 0 : (w.pay / w.hours);
        if (r > 0 && wr > r * 1.35) spikes++;
      }
    }
    if (spikes < 1) return const [];

    return [
      InsightCardModel(
        id: "high_pay_spikes",
        severity: InsightSeverity.info,
        icon: Icons.star_outline,
        iconBg: ProjectColors.yellowColor.withOpacity(.3),
        iconColor: ProjectColors.yellowColor,
        title: "Some shifts paid higher than your usual rate",
        subtitle: "Could be bonuses/tips/stat pay — verify your entries.",
        score: 55,
      ),
    ];
  }

  List<InsightCardModel> _bestEarner({required OverviewModel current}) {
    if (current.jobs!.isEmpty) return const [];
    JobWeekly? best;
    for (final j in current.jobs!) {
      if (best == null || j.totals.pay > best.totals.pay) best = j;
    }
    if (best == null) return const [];

    return [
      InsightCardModel(
        id: "best_earner",
        severity: InsightSeverity.info,
        icon: Icons.trending_up,
        iconBg: ProjectColors.greenColor.withOpacity(.3),
        iconColor: ProjectColors.greenColor,
        title: "Top earner this month: ${best.jobName}",
        subtitle: "${_money(best.totals.pay)} • ${best.totals.hours.toStringAsFixed(0)}h",
        score: 60,
      ),
    ];
  }

  List<InsightCardModel> _incomeTrend({required OverviewModel current, required OverviewModel? previous}) {
    if (previous == null) return const [];
    if (previous.totals!.pay <= 0) return const [];

    final ch = current.totals!.pay;
    final ph = previous.totals!.pay;
    final change = ((ch - ph) / ph) * 100.0;

    final up = change >= 0;
    final abs = change.abs();

    return [
      InsightCardModel(
        id: "income_trend",
        severity: up ? InsightSeverity.good : InsightSeverity.warn,
        icon: up ? Icons.arrow_upward : Icons.arrow_downward,
        iconBg: up ? ProjectColors.greenColor.withOpacity(.3) : ProjectColors.errorColor.withOpacity(.3),
        iconColor: up ? ProjectColors.greenColor : ProjectColors.errorColor,
        title: "Income is ${up ? "up" : "down"} ${_pct(abs)} vs last month",
        subtitle: "Last: ${_money(ph)} • Now: ${_money(ch)}",
        score: abs >= 15 ? 88 : 65,
      ),
    ];
  }

  List<InsightCardModel> _payRateComparison({required OverviewModel current}) {
    if (current.jobs!.length < 2) return const [];

    final jobs = current.jobs!.toList();
    jobs.sort((a, b) => _avgRate(b).compareTo(_avgRate(a)));

    final top = jobs.first;
    final low = jobs.last;
    final d = _avgRate(top) - _avgRate(low);

    if (d <= 1.0) return const [];

    return [
      InsightCardModel(
        id: "rate_compare",
        severity: InsightSeverity.info,
        icon: Icons.compare_arrows,
        iconBg: ProjectColors.greenColor.withOpacity(.3),
        iconColor: ProjectColors.greenColor,
        title: "${top.jobName} pays about ${_money(d)}/h more than ${low.jobName}",
        subtitle: "Based on this month’s averages.",
        score: d >= 4 ? 78 : 55,
      ),
    ];
  }

  List<InsightCardModel> _swapSuggestion({required OverviewModel current, required InsightSettings settings}) {
    if (!settings.enableSwapSuggestion!) return const [];
    if (current.jobs!.length < 2) return const [];

    final jobs = current.jobs!.toList();
    jobs.sort((a, b) => _avgRate(b).compareTo(_avgRate(a)));

    final best = jobs.first;
    final worst = jobs.last;
    final diff = _avgRate(best) - _avgRate(worst);

    if (diff <= 2.0) return const [];

    const shiftHours = 3.0; // conservative
    final estMonthlyGain = diff * shiftHours * 4;

    return [
      InsightCardModel(
        id: "swap_suggestion",
        severity: InsightSeverity.info,
        icon: Icons.lightbulb_outline,
        iconBg: ProjectColors.yellowColor.withOpacity(.3),
        iconColor: ProjectColors.yellowColor,
        title: "Shifting ${shiftHours.toStringAsFixed(0)}h/week from ${worst.jobName} to ${best.jobName} could add ~${_money(estMonthlyGain)}/month",
        subtitle: "Only applies if you can actually move hours.",
        score: 72,
      ),
    ];
  }

  // List<InsightCardModel> _nextDepositCountdown({required OverviewModel current, required DateTime now}) {
  //   final nd = current.nextDeposit;
  //   if (nd == null) return const [];
  //
  //   // If viewing a past month, don’t show “next deposit”
  //   final viewMonth = DateTime(current.month!.year, current.month!.month);
  //   final currentMonth = DateTime(now.year, now.month);
  //   if (viewMonth.isBefore(currentMonth)) return const [];
  //
  //   final d = _daysBetween(now, nd);
  //   if (d < 0) return const [];
  //
  //   return [
  //     InsightCardModel(
  //       id: "next_deposit",
  //       severity: d <= 3 ? InsightSeverity.good : InsightSeverity.info,
  //       icon: Icons.attach_money,
  //       iconBg: ProjectColors.greenColor.withOpacity(.16),
  //       title: "Next deposit in $d day${d == 1 ? "" : "s"}",
  //       subtitle: "Estimated from your pay periods.",
  //       score: d <= 3 ? 85 : 50,
  //     ),
  //   ];
  // }

  /// You don’t have explicit deposit dates per week. This is a safe “cadence risk” proxy.
  List<InsightCardModel> _cashGapProxy({required OverviewModel current}) {
    final allWeeks = <WeekRow>[];
    for (final j in current.jobs!) {
      allWeeks.addAll(j.weeks);
    }
    if (allWeeks.length < 3) return const [];

    allWeeks.sort((a, b) => a.start.compareTo(b.start));

    int maxGap = 0;
    for (int i = 1; i < allWeeks.length; i++) {
      final gap = allWeeks[i].start.difference(allWeeks[i - 1].start).inDays.abs();
      if (gap > maxGap) maxGap = gap;
    }

    if (maxGap < 10) return const [];

    return [
      InsightCardModel(
        id: "cash_gap_proxy",
        severity: InsightSeverity.warn,
        icon: Icons.ssid_chart,
        iconBg: ProjectColors.errorColor.withOpacity(.3),
        iconColor: ProjectColors.errorColor,
        title: "Cashflow may have long gaps this month (up to ~$maxGap days)",
        subtitle: "Plan expenses around your pay cadence.",
        score: 80,
      ),
    ];
  }
}
