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
  /// You set these from your Overview screen when month changes.
  RxList<OverviewModel> depositData = RxList<OverviewModel>([]);
  Rxn<OverviewModel>? current = Rxn<OverviewModel>();
  Rxn<OverviewModel>? previous = Rxn<OverviewModel>();
  Rxn<LineChartCardModel>? weekChart = Rxn<LineChartCardModel>();
  Rxn<LineChartCardModel>? sixMonthChart = Rxn<LineChartCardModel>();
  Rxn<DepositInsightsVM>? depositInsight = Rxn<DepositInsightsVM>();
  Rx<DateTime> selectedMonth = Rx<DateTime>(DateTime.now());

  /// Call this when you load month data
  void setOverviews() {
    depositData.value = shift.buildCombinedOverviews();
    if (depositData.isNotEmpty) {
      depositData.sort((a, b) => monthName(b.month!).compareTo(monthName(a.month!)));
      current!.value = depositData.first;
      // previous becomes the next item if it exists and is exactly previous month
      if (depositData.length > 2) {
        final expectedPrev = DateTime(selectedMonth.value.year, selectedMonth.value.month - 1, 1);
        previous!.value = depositData.firstWhereOrNull((x) => monthName(x.month!) == monthName(expectedPrev))!;
      }
      weekChart!.value = buildWeeklyBreakdownCard();
      sixMonthChart!.value = buildMonthlyTrendCard();
      depositInsight!.value = computeDepositInsightsFromShifts();
    }
    current!.refresh();
    previous!.refresh();
    depositInsight!.refresh();
    sixMonthChart!.refresh();
    weekChart!.refresh();
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
    if (depositData.any((t) => monthName(t.month!) == monthName(next))) {
      selectedMonth.value = next;
      selectedMonth.refresh();
      setOverviews();
    } else {
      showSnackBar("Error: No Previous Month", "You don’t have any shift records from the previous month.");
    }
  }

  void goToPreviousMonth() => shiftMonth(-1);
  void goToNextMonth() => shiftMonth(1);

  DepositInsightsVM computeDepositInsightsFromShifts() {
    JobWeekly? topJobByPay;
    List<ShiftDay>? bestDay = [];
    WeekRow? bestWeek;
    var surplus = previous!.value == null
        ? 0.0
        : (((current!.value!.totals!.pay - previous!.value!.totals!.pay) / previous!.value!.totals!.pay) * 100).toPrecision(2);
    var earningEffCurrent = (current!.value!.totals!.pay / current!.value!.totals!.hours).toPrecision(2);
    var earningEffPrevious = previous!.value == null ? 0.0 : (previous!.value!.totals!.pay / previous!.value!.totals!.hours).toPrecision(2);
    var earningEffChange = previous!.value == null ? 0.0 : (((earningEffCurrent - earningEffPrevious) / earningEffPrevious) * 100).toPrecision(2);
    final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.value.year, selectedMonth.value.month);
    final jobs = current!.value!.jobs;
    // Find the month bucket inside ShiftModel
    final monthKey = "${selectedMonth.value.year.toString().padLeft(4, '0')}-${selectedMonth.value.month.toString().padLeft(2, '0')}";
    final monthBucket =
        shift.shifts!.firstWhere((m) => (m.month ?? '').startsWith(monthKey), orElse: () => ShiftMonth(month: monthKey, dates: const []));
    final shiftDays = monthBucket.dates ?? const <ShiftDay>[];
    jobs!.sort((a, b) => b.totals.pay.compareTo(a.totals.pay));
    topJobByPay = jobs.first;

    // Flatten all shifts for this month and compute daily totals
    double maxIncome1 = double.negativeInfinity;
    double maxIncome2 = double.negativeInfinity;
    for (final d in shiftDays) {
      final income = (d.totalDayIncome ?? 0.0);

      if (income > maxIncome1) {
        maxIncome1 = income;
        bestDay
          ..clear()
          ..add(d);
      } else if (income == maxIncome1) {
        bestDay.add(d);
      }
    }

    for (var files in jobs) {
      for (var items in files.weeks) {
        if (items.pay > maxIncome2) {
          maxIncome2 = items.pay;
          bestWeek = items;
        }
      }
    }
    return DepositInsightsVM(
      monthLabel: monthName(selectedMonth.value),
      isCurrentMonth: true,
      jobCount: 1,
      monthTotal: current!.value!.totals!.pay,
      monthChangePct: surplus,
      efficiency: earningEffCurrent.toPrecision(1),
      efficiencyChangePct: earningEffChange.toPrecision(1),
      bestDayLabel: bestDay,
      bestDayEarned: bestDay[0].totalDayIncome,
      bestWeekLabel: '${DateFormat('EEE dd').format(bestWeek!.start)}-${DateFormat('EEE dd').format(bestWeek.end)}',
      bestWeekEarned: bestWeek.pay.toPrecision(1),
      workedDays: shiftDays.length,
      daysInMonth: daysInMonth,
      topSourceName: topJobByPay.jobName,
      topSourceValue: topJobByPay.totals.pay,
      topSourceSharePct: ((topJobByPay.totals.pay / current!.value!.totals!.pay) * 100).toPrecision(1),
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

    final dataMap = <String, OverviewModel>{};
    for (final m in depositData) {
      if (m.month == null) continue;
      final k = key(DateTime(m.month!.year, m.month!.month, 1));
      dataMap[k] = m;
    }

    // 3) Build labels + values
    final xLabels = <String>[];
    final values = <double>[];

    for (final d in months) {
      xLabels.add(_shortMonth(d)); // "Jun"
      final ov = dataMap[key(d)];
      values.add(ov == null ? 0.0 : _monthTotal(ov, Metric.pay));
    }

    final int currentIndex = values.isEmpty ? 0 : values.length - 1;
    final double currentMonthPay = values.isEmpty ? 0.0 : values[currentIndex];

    // 5) Surplus vs previous month (safe)
    double surplusPct = 0.0;
    if (values.length >= 2) {
      final prev = values[currentIndex - 1];
      if (prev == 0) {
        surplusPct = currentMonthPay == 0 ? 0.0 : 0.0;
      } else {
        surplusPct = (((currentMonthPay - prev) / prev) * 100).toPrecision(2);
      }
    }

    return LineChartCardModel(
      title: "Monthly Deposits - Last 6 Months",
      totalText: "\$ ${currentMonthPay.toStringAsFixed(0)}",
      changeText: values.length < 2
          ? "0"
          : (values[currentIndex - 1] == 0 && currentMonthPay != 0)
              ? "N/A"
              : '$surplusPct %',
      xLabels: xLabels,
      values: values,
      height: height * .2,
      color: (values.length >= 2 && surplusPct < 0) ? ProjectColors.errorColor : const Color(0xFF22C55E),
    );
  }

  List<double> combineWeeklyPays() {
    final m = current!.value;
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

    for (var files in current!.value!.jobs![0].weeks) {
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
