import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../../../models/Deposit Model.dart';
import '../../../models/Overview Model.dart';
import '../../../models/shift.dart';
import '../../Constant UI.dart';
import '../../Constants.dart';
import '../../Controllers.dart';
import 'package:fl_chart/fl_chart.dart';

import '../Overview/OverviewGetx.dart';

/// ---------------------------------------------------------------------------
/// INSIGHTS (GetX Controller)
/// ---------------------------------------------------------------------------

enum Metric { pay, hours }

double _monthTotal(OverviewModel m, Metric metric) {
  double sum = 0;
  for (final job in m.jobs ?? const []) {
    for (final w in job.weeks) {
      sum += metric == Metric.pay ? w.pay : w.hours;
    }
  }
  return sum;
}

String _shortMonth(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return m[d.month - 1];
}

class DepositsController extends GetxController {
  Rxn<OverviewModel>? currentMonthDeposit = Rxn<OverviewModel>();
  Rxn<OverviewModel>? previousMonthDeposit = Rxn<OverviewModel>();
  Rxn<ShiftMonth>? currentMonthShift = Rxn<ShiftMonth>();
  Rxn<LineChartCardModel>? weekChart = Rxn<LineChartCardModel>();
  Rxn<LineChartCardModel>? sixMonthChart = Rxn<LineChartCardModel>();
  Rxn<DepositInsightsVM>? depositInsight = Rxn<DepositInsightsVM>();

  /// You set these from your Overview screen when month changes.
  // RxList<OverviewModel> depositData = RxList<OverviewModel>([]);
  // Rxn<ShiftMonth>? currentMonth = Rxn<ShiftMonth>();
  // Rxn<OverviewModel>? current = Rxn<OverviewModel>();
  // Rxn<OverviewModel>? previous = Rxn<OverviewModel>();

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
    currentMonthDeposit!.value = shift.buildOverviewForMonth(nextMonthData);
    final prevDate = DateTime(next.year, next.month - 1, 1);
    final prevData = shift.getCurrentData(prevDate);
    previousMonthDeposit!.value =
        prevData == null ? OverviewModel(month: prevDate, totals: Totals(hours: 0, pay: 0), jobs: const []) : shift.buildOverviewForMonth(prevData);
    weekChart!.value = buildWeeklyBreakdownCard();
    depositInsight!.value = computeDepositInsightsFromShifts();
    sixMonthChart!.value = buildMonthlyTrendCard();
    // insights!.value = computeOverviewInsights(
    //   current: currentMonthDeposit!.value,
    //   previous: previousMonthDeposit!.value, // can be null
    //   shiftMonth: currentMonthShift!.value, // you said always available
    //   settings: InsightSettings(
    //     monthlyIncomeGoal: 2500, // or from user prefs
    //     safeWeeklyHoursLimit: 50, // or from user prefs
    //     otThreshold: 40,
    //   ),
    //   now: DateTime.now(),
    // );
  }

  /// Call this when you load month data
  // void setOverviews() {
  //   currentMonth!.value = shift.getCurrentData(selectedMonth.value);
  //   current!.value = shift.buildOverviewForMonth(currentMonth!.value!);
  //   if (depositData.isNotEmpty) {
  //     depositData.sort((a, b) => monthName(b.month!).compareTo(monthName(a.month!)));
  //     current!.value = depositData.first;
  //     // previous becomes the next item if it exists and is exactly previous month
  //     if (depositData.length > 2) {
  //       final expectedPrev = DateTime(selectedMonth.value.year, selectedMonth.value.month - 1, 1);
  //       previous!.value = depositData.firstWhereOrNull((x) => monthName(x.month!) == monthName(expectedPrev))!;
  //     }
  //     weekChart!.value = buildWeeklyBreakdownCard();
  //     sixMonthChart!.value = buildMonthlyTrendCard();
  //     // depositInsight!.value = computeDepositInsightsFromShifts();
  //   }
  //   current!.refresh();
  //   previous!.refresh();
  //   depositInsight!.refresh();
  //   sixMonthChart!.refresh();
  //   weekChart!.refresh();
  // }

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

  void goToPreviousMonth() => shiftMonth(-1);
  void goToNextMonth() => shiftMonth(1);

  // DepositInsightsVM computeDepositInsightsFromShifts() {
  //   JobWeekly? topJobByPay;
  //   List<ShiftDay>? bestDay = [];
  //   WeekRow? bestWeek;
  //   var surplus = previousMonthDeposit!.value == null
  //       ? 0.0
  //       : (((currentMonthDeposit!.value!.totals!.pay - previousMonthDeposit!.value!.totals!.pay) / previousMonthDeposit!.value!.totals!.pay) * 100)
  //           .toPrecision(2);
  //   var earningEffCurrent = (currentMonthDeposit!.value!.totals!.pay / currentMonthDeposit!.value!.totals!.hours).toPrecision(2);
  //   var earningEffPrevious = previousMonthDeposit!.value == null
  //       ? 0.0
  //       : (previousMonthDeposit!.value!.totals!.pay / previousMonthDeposit!.value!.totals!.hours).toPrecision(2);
  //   var earningEffChange =
  //       previousMonthDeposit!.value == null ? 0.0 : (((earningEffCurrent - earningEffPrevious) / earningEffPrevious) * 100).toPrecision(2);
  //   final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.value.year, selectedMonth.value.month);
  //   final jobs = currentMonthDeposit!.value!.jobs;
  //   // Find the month bucket inside ShiftModel
  //   final monthKey = "${selectedMonth.value.year.toString().padLeft(4, '0')}-${selectedMonth.value.month.toString().padLeft(2, '0')}";
  //   final monthBucket =
  //       shift.shifts!.firstWhere((m) => (m.month ?? '').startsWith(monthKey), orElse: () => ShiftMonth(month: monthKey, dates: const []));
  //   final shiftDays = monthBucket.dates ?? const <ShiftDay>[];
  //   jobs!.sort((a, b) => b.totals.pay.compareTo(a.totals.pay));
  //   topJobByPay = jobs.first;
  //
  //   // Flatten all shifts for this month and compute daily totals
  //   double maxIncome1 = double.negativeInfinity;
  //   double maxIncome2 = double.negativeInfinity;
  //   for (final d in shiftDays) {
  //     final income = (d.totalDayIncome ?? 0.0);
  //
  //     if (income > maxIncome1) {
  //       maxIncome1 = income;
  //       bestDay
  //         ..clear()
  //         ..add(d);
  //     } else if (income == maxIncome1) {
  //       bestDay.add(d);
  //     }
  //   }
  //
  //   for (var files in jobs) {
  //     for (var items in files.weeks) {
  //       if (items.pay > maxIncome2) {
  //         maxIncome2 = items.pay;
  //         bestWeek = items;
  //       }
  //     }
  //   }
  //   return DepositInsightsVM(
  //     monthLabel: monthName(selectedMonth.value),
  //     isCurrentMonth: true,
  //     jobCount: 1,
  //     monthTotal: currentMonthDeposit!.value!.totals!.pay,
  //     monthChangePct: surplus,
  //     efficiency: earningEffCurrent.toPrecision(1),
  //     efficiencyChangePct: earningEffChange.toPrecision(1),
  //     bestDayLabel: bestDay,
  //     bestDayEarned: bestDay[0].totalDayIncome,
  //     bestWeekLabel: '${DateFormat('EEE dd').format(bestWeek!.start)}-${DateFormat('EEE dd').format(bestWeek.end)}',
  //     bestWeekEarned: bestWeek.pay.toPrecision(1),
  //     workedDays: shiftDays.length,
  //     daysInMonth: daysInMonth,
  //     topSourceName: topJobByPay.jobName,
  //     topSourceValue: topJobByPay.totals.pay,
  //     topSourceSharePct: ((topJobByPay.totals.pay / currentMonthDeposit!.value!.totals!.pay) * 100).toPrecision(1),
  //     projectedMonthEnd: 0,
  //   );
  // }
  DepositInsightsVM computeDepositInsightsFromShifts() {
    final cur = currentMonthDeposit?.value;

    // --- empty state
    if (cur == null || cur.totals == null) {
      return DepositInsightsVM(
        monthLabel: monthName(selectedMonth.value),
        isCurrentMonth: true,
        jobCount: 0,
        monthTotal: 0,
        monthChangePct: 0,
        efficiency: 0,
        efficiencyChangePct: 0,
        bestDayLabel: const [],
        bestDayEarned: 0,
        bestWeekLabel: "-",
        bestWeekEarned: 0,
        workedDays: 0,
        daysInMonth: DateUtils.getDaysInMonth(selectedMonth.value.year, selectedMonth.value.month),
        topSourceName: "-",
        topSourceValue: 0,
        topSourceSharePct: 0,
        projectedMonthEnd: 0,
      );
    }

    // --- helpers
    double pctChange(double now, double old) {
      if (old == 0) return 0.0; // UI can show N/A if you want
      return (((now - old) / old) * 100).toPrecision(2);
    }

    double safeRate(double pay, double hours) => (hours <= 0) ? 0.0 : (pay / hours);

    double shiftHours(AllShifts s) {
      final st = s.start, en = s.end;
      if (st == null || en == null) return 0.0;

      var end = en;
      if (end.isBefore(st)) end = end.add(const Duration(days: 1)); // cross-midnight

      var mins = end.difference(st).inMinutes - (s.breakMin ?? 0);
      if (mins < 0) mins = 0;
      return mins / 60.0;
    }

    // --- core numbers
    final prev = previousMonthDeposit?.value;

    final curPay = cur.totals!.pay;
    final curHours = cur.totals!.hours;

    final prevPay = prev?.totals?.pay ?? 0.0;
    final prevHours = prev?.totals?.hours ?? 0.0;

    final monthChangePct = pctChange(curPay, prevPay);

    final effCur = safeRate(curPay, curHours);
    final effPrev = safeRate(prevPay, prevHours);
    final effChangePct = (effPrev <= 0) ? 0.0 : pctChange(effCur, effPrev);

    final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.value.year, selectedMonth.value.month);

    // --- jobs
    final jobs = (cur.jobs ?? const <JobWeekly>[]).toList()
      ..sort((a, b) => b.totals.pay.compareTo(a.totals.pay));
    final topJob = jobs.isEmpty ? null : jobs.first;

    // rate map (fallback when shift.income == null)
    final rateByJobId = <int, double>{};
    for (final j in jobs) {
      rateByJobId[j.jobId] = safeRate(j.totals.pay, j.totals.hours);
    }

    // --- shifts (current month bucket already provided)
    final shiftDays = currentMonthShift?.value?.dates ?? const <ShiftDay>[];

    final workedDays = shiftDays.where((d) => (d.data?.isNotEmpty ?? false)).length;

    // --- best day (uses income if present; else estimate using rate * hours)
    ShiftDay? bestDay;
    double bestDayIncome = -1;

    for (final d in shiftDays) {
      final dayIncome = (d.data ?? const <AllShifts>[]).fold<double>(0.0, (sum, sh) {
        final inc = sh.income;
        if (inc != null) return sum + inc;

        final jid = sh.jobFrom?.id;
        final id = (jid is int) ? jid : int.tryParse(jid?.toString() ?? '');
        final rate = (id == null) ? 0.0 : (rateByJobId[id] ?? 0.0);

        return sum + (rate * shiftHours(sh));
      });

      if (dayIncome > bestDayIncome) {
        bestDayIncome = dayIncome;
        bestDay = d;
      }
    }

    // --- best week
    WeekRow? bestWeek;
    double bestWeekPay = -1;

    for (final j in jobs) {
      for (final w in j.weeks) {
        if (w.pay > bestWeekPay) {
          bestWeekPay = w.pay;
          bestWeek = w;
        }
      }
    }

    final bestWeekLabel = (bestWeek == null)
        ? "-"
        : "${DateFormat('EEE dd').format(bestWeek.start)}-${DateFormat('EEE dd').format(bestWeek.end)}";

    // --- result
    return DepositInsightsVM(
      monthLabel: monthName(selectedMonth.value),
      isCurrentMonth: true,

      jobCount: jobs.length,
      monthTotal: curPay,
      monthChangePct: monthChangePct,

      efficiency: effCur.toPrecision(1),
      efficiencyChangePct: effChangePct.toPrecision(1),

      bestDayLabel: bestDay == null ? const [] : <ShiftDay>[bestDay],
      bestDayEarned: bestDayIncome < 0 ? 0.0 : bestDayIncome.toPrecision(1),

      bestWeekLabel: bestWeekLabel,
      bestWeekEarned: (bestWeek?.pay ?? 0.0).toPrecision(1),

      workedDays: workedDays,
      daysInMonth: daysInMonth,

      topSourceName: topJob?.jobName ?? "-",
      topSourceValue: topJob?.totals.pay ?? 0.0,
      topSourceSharePct: (topJob == null || curPay <= 0) ? 0.0 : ((topJob.totals.pay / curPay) * 100).toPrecision(1),

      projectedMonthEnd: 0,
    );
  }


  LineChartCardModel buildMonthlyTrendCard() {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month, 1);

    final months = List<DateTime>.generate(6, (i) {
      final d = DateTime(anchor.year, anchor.month - (5 - i), 1);
      return DateTime(d.year, d.month, 1);
    });

    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
    String keyOfMonth(DateTime? m) => m == null ? '' : key(DateTime(m.year, m.month, 1));

    // We only have ONE month now
    final ov = currentMonthDeposit!.value;
    final ovKey = keyOfMonth(ov?.month);

    final xLabels = <String>[];
    final values = <double>[];

    for (final d in months) {
      xLabels.add(_shortMonth(d)); // your helper
      if (ov != null && ovKey == key(d)) {
        values.add(_monthTotal(ov, Metric.pay)); // your helper
      } else {
        values.add(0.0);
      }
    }

    final int currentIndex = values.isEmpty ? 0 : values.length - 1;
    final double currentMonthPay = values.isEmpty ? 0.0 : values[currentIndex];

    double surplusPct = 0.0;
    String changeText = "0";

    if (values.length >= 2) {
      final prev = values[currentIndex - 1];
      if (prev == 0) {
        changeText = (currentMonthPay == 0) ? "0" : "N/A";
        surplusPct = 0.0;
      } else {
        surplusPct = (((currentMonthPay - prev) / prev) * 100).toPrecision(2);
        changeText = "$surplusPct %";
      }
    }

    return LineChartCardModel(
      title: "Monthly Deposits - Last 6 Months",
      totalText: "\$ ${currentMonthPay.toStringAsFixed(0)}",
      changeText: changeText,
      xLabels: xLabels,
      values: values,
      height: height * .2,
      color: (values.length >= 2 && surplusPct < 0) ? ProjectColors.errorColor : const Color(0xFF22C55E),
    );
  }

  List<double> combineWeeklyPays() {
    final m = currentMonthDeposit!.value;
    if (m == null || m.jobs == null || m.jobs!.isEmpty) return const [];
    final Map<int, double> byWeek = {};
    for (final job in m.jobs!) {
      for (final w in job.weeks) {
        byWeek[w.weekIndex] = (byWeek[w.weekIndex] ?? 0.0) + w.pay;
      }
    }
    final keys = byWeek.keys.toList()..sort();
    return [for (final k in keys) byWeek[k] ?? 0.0];
  }

  LineChartCardModel buildWeeklyBreakdownCard() {
    List<String> weeks = [];
    List<double> weekPay = combineWeeklyPays();
    double currentWeekPay = 0;
    double calculateSurplus = 0.0;

    for (var files in currentMonthDeposit!.value!.jobs![0].weeks) {
      int weekStart = int.parse(monthDate(files.start));
      int weekEnd = int.parse(monthDate(files.end));
      int currentDate = int.parse(monthDate(DateTime.now()));
      final isBetween = currentDate >= weekStart && currentDate <= weekEnd;
      if (isBetween) {
        currentWeekPay = weekPay[files.weekIndex - 1];
        calculateSurplus = (((currentWeekPay - weekPay[files.weekIndex - 2]) / weekPay[files.weekIndex - 2]) * 100).toPrecision(2);
      }
      weeks.add("$weekStart - $weekEnd");
    }

    return LineChartCardModel(
      title: 'Weekly Breakdown for ${monthName(selectedMonth.value)}',
      totalText: "\$ $currentWeekPay",
      changeText: calculateSurplus == 0.0 ? "N/A" : '$calculateSurplus %',
      xLabels: weeks,
      values: weekPay,
      height: height * .2,
      color: calculateSurplus > 0 ? Color(0xFF22C55E) : ProjectColors.errorColor,
    );
  }
}
