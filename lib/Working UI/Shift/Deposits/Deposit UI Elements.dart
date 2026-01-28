import 'dart:math';

import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

import '../../../models/Deposit Model.dart';
import '../../Constant UI.dart';
import '../../Constants.dart';

class MonthlyKpiBarCard extends StatelessWidget {
  const MonthlyKpiBarCard({
    super.key,
    required this.title,
    required this.totalText,
    required this.changeText,
    required this.xLabels,
    required this.values,
    required this.color,
  }) : assert(xLabels.length == values.length, 'xLabels and values must have same length');

  final String title;
  final String totalText;
  final String changeText;
  final List<String> xLabels;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || xLabels.isEmpty) {
      return DarkCard(child: const SizedBox(height: 140, child: Center(child: Text("No data"))));
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.15;

    const gridColor = Color(0xFF1F2937);

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: title,
            fontSize: .018,
            fontWeight: FontWeight.bold,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .01),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              textWidget(
                text: totalText,
                fontSize: .035,
                fontWeight: FontWeight.bold,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(width: width * .03),
              textWidget(
                text: changeText,
                fontSize: .02,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              Visibility(visible: changeText.contains('N/A') ? false : true, child: Icon(Entypo.arrow_bold_up, size: height * .04, color: color)),
            ],
          ),
          SizedBox(height: height * .02),
          SizedBox(
            height: height * .15, // same as line chart
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround, // looks closer to your mock
                borderData: FlBorderData(show: false),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: gridColor.withOpacity(0.6),
                    strokeWidth: 1,
                  ),
                ),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (v, meta) {
                        final txt = _compactCurrency(v);
                        return textWidget(
                          text: txt,
                          fontSize: .012,
                          color: ProjectColors.whiteColor.withOpacity(0.5),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= xLabels.length) return const SizedBox();
                        return Padding(
                          padding: EdgeInsets.only(top: height * .01),
                          child: textWidget(
                            text: xLabels[i],
                            fontSize: .012,
                            color: ProjectColors.whiteColor.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                barGroups: [
                  for (int i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 0,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          // make bar thickness responsive instead of hard-coded 56
                          width: width * 0.16, // tweak: 0.035–0.06 based on your card width
                          borderRadius: BorderRadius.circular(15),
                          color: ProjectColors.greenColor, // keep bars green like your mock
                        ),
                      ],
                    ),
                ],
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
              swapAnimationCurve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  static String _compactCurrency(double v) {
    final n = v.round();
    if (n >= 1000) return '\$${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '\$$n';
  }
}

class MonthlyKpiLineCard extends StatelessWidget {
  const MonthlyKpiLineCard({
    super.key,
    required this.title,
    required this.totalText,
    required this.changeText,
    required this.xLabels,
    required this.values,
    required this.color,
  });

  final String title; // "Weekly Comparison for November"
  final String totalText; // "$2,990"
  final String changeText; // "+21%"
  final List<String> xLabels; // ["Jun","Jul","Aug","Sep","Oct","Nov"]
  final List<double> values; // same length as xLabels
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || xLabels.isEmpty) {
      return DarkCard(child: const SizedBox(height: 140, child: Center(child: Text("No data"))));
    }

    final spots = <FlSpot>[
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxVal - minVal).abs() * 0.15;
    final minY = (minVal - (pad == 0 ? 1 : pad)).clamp(-double.infinity, double.infinity);
    final maxY = (maxVal + (pad == 0 ? 1 : pad)).clamp(-double.infinity, double.infinity);

    const lineColor = ProjectColors.greenColor; // green like your image
    const gridColor = Color(0xFF1F2937);

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: title,
            fontSize: .018,
            fontWeight: FontWeight.bold,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .01),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              textWidget(
                text: totalText,
                fontSize: .035,
                fontWeight: FontWeight.bold,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(width: width * .03),
              textWidget(
                text: changeText,
                fontSize: .02,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              Visibility(visible: changeText.contains('N/A') ? false : true, child: Icon(Entypo.arrow_bold_up, size: height * .04, color: color)),
            ],
          ),
          SizedBox(height: height * .02),
          SizedBox(
            height: height * .15,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                backgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),

                // Minimal grid: only faint horizontal lines
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  // horizontalInterval: _niceInterval(minY, maxY),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: gridColor.withOpacity(0.6),
                    strokeWidth: 1,
                  ),
                ),

                // Axis labels: bottom months only; left optional like image
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      // interval: _niceInterval(minY, maxY),
                      getTitlesWidget: (v, meta) {
                        // show fewer labels to keep it clean
                        final txt = _compactCurrency(v);
                        return textWidget(text: txt, fontSize: .012, color: ProjectColors.whiteColor.withOpacity(0.5));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        // if (i < 0 || i >= xLabels.length) return const SizedBox();
                        return Padding(
                          padding: EdgeInsets.only(top: height * .01),
                          child: textWidget(
                            text: xLabels[i],
                            fontSize: .012,
                            color: ProjectColors.whiteColor.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // No touch highlight line, but keep tooltip if you want
                // lineTouchData: LineTouchData(
                //   enabled: true,
                //   handleBuiltInTouches: true,
                //   getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((_) {
                //     return TouchedSpotIndicatorData(
                //       FlLine(color: Colors.transparent),
                //       FlDotData(show: false),
                //     );
                //   }).toList(),
                //   touchTooltipData: LineTouchTooltipData(
                //     tooltipBorderRadius: BorderRadius.circular(10),
                //     // tooltipBgColor: const Color(0xFF111827),
                //     getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                //       final i = s.x.toInt();
                //       final label = (i >= 0 && i < xLabels.length) ? xLabels[i] : '';
                //       return LineTooltipItem(
                //         '$label  ${_compactCurrency(s.y)}',
                //         const TextStyle(color: textColor, fontWeight: FontWeight.w600),
                //       );
                //     }).toList(),
                //   ),
                // ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    barWidth: height * .002,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false), // IMPORTANT: no dots (like your image)
                    color: lineColor,

                    // Soft green area fill
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withOpacity(0.50),
                          lineColor.withOpacity(0.00),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  // static double _niceInterval(double minY, double maxY) {
  //   final r = (maxY - minY).abs();
  //   if (r <= 5) return 1;
  //   if (r <= 10) return 2;
  //   if (r <= 25) return 5;
  //   if (r <= 50) return 10;
  //   if (r <= 100) return 20;
  //   if (r <= 500) return 100;
  //   if (r <= 2000) return 500;
  //   return 1000;
  // }

  static String _compactCurrency(double v) {
    // You can swap this for NumberFormat if you use intl
    final n = v.round();
    if (n >= 1000) return '\$${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '\$$n';
  }
}

/// ---------------------------
/// SCREEN
/// ---------------------------
// ---------------------------

// ---------------------------
// HELPERS
// ---------------------------
String _money(double v, {int decimals = 0}) => '\$${v.toStringAsFixed(decimals)}';

String _pctText(double? pct) {
  if (pct == null || pct.isNaN || pct.isInfinite) return 'N/A';
  final sign = pct > 0 ? '+' : '';
  return '$sign${pct.toStringAsFixed(0)}%';
}

Color _trendColor(double? pct) {
  if (pct == null || pct.isNaN || pct.isInfinite) return ProjectColors.whiteColor.withOpacity(0.45);
  if (pct < 0) return ProjectColors.errorColor;
  return ProjectColors.greenColor;
}

// ---------------------------
// SCREEN (Stacked cards like mock)
// ---------------------------
class DepositInsightsScreen extends StatelessWidget {
  const DepositInsightsScreen({
    super.key,
    required this.vm,
    this.showAll = false,
  });

  final DepositInsightsVM vm;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        children: [
          _SummaryCard(vm: vm),
          SizedBox(height: height * .025),
          if (showAll || vm.efficiency != null) _EfficiencyCard(vm: vm, showAll: showAll),
          SizedBox(height: height * .025),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showAll || vm.bestDayLabel != null) _BestDayCard(),
              SizedBox(height: height * .025),
              if (showAll || vm.bestDayLabel != null) _BestWeekCard(),
            ],
          ),
          SizedBox(height: height * .025),
          if (showAll || vm.isMultiJob) _TopSourceCard(),
          SizedBox(height: height * .025),
          if (showAll || !vm.isMultiJob) _WorkedDaysCard(),
        ],
      ),
    );
  }
}

// ---------------------------
// 1) SUMMARY CARD
// ---------------------------
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.vm});
  final DepositInsightsVM vm;

  @override
  Widget build(BuildContext context) {
    final c = _trendColor(vm.monthChangePct);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: "Deposit Insights · ${vm.monthLabel}",
          fontSize: .02,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor.withOpacity(0.9),
        ),
        Row(
          children: [
            textWidget(
              text: _money(vm.monthTotal!, decimals: 0),
              fontSize: .045,
              fontWeight: FontWeight.w800,
              color: ProjectColors.whiteColor,
            ),
            SizedBox(width: width * .02),
            Icon(
              (vm.monthChangePct ?? 0) < 0 ? Entypo.arrow_bold_down : Entypo.arrow_bold_up,
              size: height * .022,
              color: c,
            ),
            SizedBox(width: width * .015),
            textWidget(
              text: "${vm.monthChangePct} vs ${monthName(DateTime(deposit.selectedMonth.value.year, deposit.selectedMonth.value.month - 1, 1))}",
              fontSize: .018,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ],
        ),
        textWidget(
          text: vm.isCurrentMonth! ? "Month-to-date" : "Final month total",
          fontSize: .016,
          color: ProjectColors.whiteColor.withOpacity(0.55),
        ),
      ],
    );
  }
}

// ---------------------------
// 2) EFFICIENCY CARD + ring
// ---------------------------
class _EfficiencyCard extends StatelessWidget {
  const _EfficiencyCard({required this.vm, required this.showAll});
  final DepositInsightsVM vm;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    final eff = vm.efficiency ?? 0.0;
    final effC = _trendColor(vm.efficiencyChangePct);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: "Earnings Efficiency",
                fontSize: .02,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor,
              ),
              textWidget(
                text: "${_money(eff, decimals: 2)} / hour",
                fontSize: .03,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(height: height * .006),
              Row(
                children: [
                  Icon(
                    (vm.efficiencyChangePct ?? 0) < 0 ? Entypo.arrow_bold_down : Entypo.arrow_bold_up,
                    size: height * .02,
                    color: effC,
                  ),
                  SizedBox(width: width * .012),
                  textWidget(
                    text: "${_pctText(vm.efficiencyChangePct)} vs last month",
                    fontSize: .018,
                    fontWeight: FontWeight.w700,
                    color: effC,
                  ),
                ],
              ),
              SizedBox(height: height * .01),
              textWidget(
                text: vm.isCurrentMonth! ? "How much you earned per hour this period." : "How much you earned per hour last month.",
                fontSize: .015,
                color: ProjectColors.whiteColor.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------
// 3) BEST DAY CARD
// ---------------------------
class _BestDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = deposit.depositInsight!.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: "Best Day",
          fontSize: .02,
          fontWeight: FontWeight.w800,
          color: ProjectColors.whiteColor,
        ),
        textWidget(
          text: '${monthName(deposit.selectedMonth.value)} ${data!.bestDayLabel![0].date}',
          fontSize: .028,
          fontWeight: FontWeight.w800,
          color: ProjectColors.whiteColor,
        ),
        Row(
          children: [
            textWidget(
              text: data.bestDayEarned!.toStringAsFixed(1),
              fontSize: .028,
              fontWeight: FontWeight.w800,
              color: ProjectColors.greenColor,
            ),
            SizedBox(width: width * .02),
            textWidget(
              text: "earned",
              fontSize: .018,
              color: ProjectColors.whiteColor.withOpacity(0.55),
            ),
          ],
        ),
        SizedBox(height: height * .01),
        textWidget(
          text: "Top earning period.",
          fontSize: .015,
          color: ProjectColors.whiteColor.withOpacity(0.55),
        ),
      ],
    );
  }
}

// ---------------------------
// 3) BEST Week CARD
// ---------------------------
class _BestWeekCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = deposit.depositInsight!.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: "Best Week",
          fontSize: .02,
          fontWeight: FontWeight.w800,
          color: ProjectColors.whiteColor,
        ),
        textWidget(
          text: data!.bestWeekLabel,
          fontSize: .028,
          fontWeight: FontWeight.w800,
          color: ProjectColors.whiteColor,
        ),
        Row(
          children: [
            textWidget(
              text: data.bestWeekEarned!.toStringAsFixed(1),
              fontSize: .028,
              fontWeight: FontWeight.w800,
              color: ProjectColors.greenColor,
            ),
            SizedBox(width: width * .02),
            textWidget(
              text: "earned",
              fontSize: .018,
              color: ProjectColors.whiteColor.withOpacity(0.55),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------
// 5) TOP SOURCE CARD (multi-job)
// ---------------------------
class _TopSourceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = deposit.depositInsight!.value;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: "Top Income Source",
                fontSize: .02,
                color: ProjectColors.whiteColor,
                fontWeight: FontWeight.w800,
              ),
              textWidget(
                text: data!.topSourceName,
                fontSize: .024,
                fontWeight: FontWeight.w800,
                color: ProjectColors.greenColor,
              ),
              SizedBox(height: height * .006),
              textWidget(
                text: "\$${data.topSourceValue} Earned",
                fontSize: .024,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(height: height * .006),
              textWidget(
                text: "${data.topSourceSharePct!.toStringAsFixed(0)}% of ${data.monthLabel} income",
                fontSize: .018,
                fontWeight: FontWeight.w700,
                color: ProjectColors.greenColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------
// 6) WORK CONSISTENCY CARD (single-job)
// ---------------------------
class _WorkedDaysCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = deposit.depositInsight!.value;
    double workPercentage = (data!.workedDays! / data.daysInMonth!) * 100;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: "Work Consistency",
                fontSize: .02,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor,
              ),
              textWidget(
                text: "You worked ${data.workedDays} days",
                fontSize: .024,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(height: height * .006),
              textWidget(
                text: "Out of ${data.daysInMonth} days · ${workPercentage.toStringAsFixed(0)}% active",
                fontSize: .016,
                color: ProjectColors.whiteColor.withOpacity(0.55),
              ),
              SizedBox(height: height * .01),
              textWidget(
                text: "Measures consistency (days with earnings).",
                fontSize: .015,
                color: ProjectColors.whiteColor.withOpacity(0.55),
              ),
            ],
          ),
        ),
        SizedBox(width: width * .03),
        _Ring(
          size: width * .28,
          accent: ProjectColors.greenColor,
          noOfDaysWorked: data.workedDays!.toDouble(),
          totalDays: data.daysInMonth!.toDouble(),
        ),
      ],
    );
  }
}

// ---------------------------
// RING (using your sizing)
// ---------------------------
class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.accent, this.noOfDaysWorked, this.totalDays});

  final double size;
  final Color accent;
  final double? noOfDaysWorked;
  final double? totalDays;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SleekCircularSlider(
        min: 0,
        max: totalDays!, // days in month
        initialValue: noOfDaysWorked!, // worked days
        appearance: CircularSliderAppearance(
          size: width * 0.33,
          startAngle: 270, // start at top
          angleRange: 360,
          customWidths: CustomSliderWidths(
            trackWidth: height * 0.012,
            progressBarWidth: height * 0.012,
            handlerSize: 0, // hide knob
            shadowWidth: 0,
          ),
          customColors: CustomSliderColors(
            trackColor: ProjectColors.greenColor.withOpacity(0.10),
            progressBarColor: ProjectColors.greenColor, // IMPORTANT: we draw gradient below
            shadowColor: Colors.transparent,
            dotColor: Colors.transparent,
          ),
          infoProperties: InfoProperties(modifier: (v) => ""),
        ),
        onChange: (_) {},
        innerWidget: (double v) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              textWidget(
                text: "${noOfDaysWorked!.toStringAsFixed(0)}/${totalDays!.toStringAsFixed(0)}",
                fontSize: .025,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(height: height * .004),
              textWidget(
                text: "Workdays",
                fontSize: .016,
                color: ProjectColors.whiteColor.withOpacity(0.65),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------
// MICRO BARS
// ---------------------------
class _MicroBars extends StatelessWidget {
  const _MicroBars({required this.labels, required this.values}) : assert(labels.length == values.length);

  final List<String> labels;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.fold<double>(0, (m, v) => max(m, v));
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return Column(
      children: [
        SizedBox(
          height: height * .07,
          width: width * .5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * .01),
                    child: Container(
                      height: height * .01 + (values[i] / safeMax) * height * .06,
                      decoration: BoxDecoration(
                        color: ProjectColors.greenColor.withOpacity(i == values.length - 1 ? 1.0 : 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: height * .008),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final l in labels) textWidget(text: l, fontSize: .014, color: ProjectColors.whiteColor.withOpacity(0.55)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------
// PROGRESS LINE
// ---------------------------
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress01});
  final double progress01;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: height * .012,
          decoration: BoxDecoration(
            color: ProjectColors.whiteColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress01.clamp(0.0, 1.0),
          child: Container(
            height: height * .012,
            decoration: BoxDecoration(
              color: ProjectColors.greenColor.withOpacity(0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}
