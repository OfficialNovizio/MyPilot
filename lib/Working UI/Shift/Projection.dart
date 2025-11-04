import 'dart:math';

import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide CustomCard;
import 'package:get/get.dart';

class ProjectionTab extends StatelessWidget {
  const ProjectionTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      shift.initJobs(app.jobs.map((e) => e.id));
      final jobs = app.jobs.where((j) => shift.jobs.contains(j.id)).toList();

      // Header controls (scope + per job hours pickers)
      final header = CustomCard(
        color: ProjectColors.whiteColor,
        title: 'Projection controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, children: [
              seg<String>(
                value: shift.projScope.value,
                items: const {'weekly': 'Weekly', 'biweekly': 'Biweekly', 'monthly': 'Monthly'},
                onChanged: (v) => shift.projScope.value = v,
              ),
            ]),
            SizedBox(height: height * .01),
            for (final j in jobs) HoursPickerRow(job: j),
            SizedBox(height: height * .01),
            textWidget(
                text: 'Projection assumes no stat-day premium and uses your job tax settings.', fontSize: .012, color: ProjectColors.pureBlackColor),
          ],
        ),
      );

      // Compute estimates
      final estPerJob = <String, Est>{};
      double gross = 0, net = 0, inc = 0, cp = 0, ei = 0, oth = 0, post = 0;
      for (final j in jobs) {
        final h = shift.projHours[j.id] ?? 30.0;
        final est = estimateForHours(app, j, shift.projScope.value, h);
        estPerJob[j.id] = est;
        gross += est.gross;
        net += est.net;
        inc += est.income;
        cp += est.cpp;
        ei += est.ei;
        oth += est.other;
        post += est.post;
      }

      // Build comparison vs last comparable period (combined)
      double prevNet = 0;
      for (final j in jobs) {
        if (shift.projScope.value == 'monthly') {
          final now = DateTime.now();
          final prev = app.monthNetSummary(DateTime(now.year, now.month - 1, 1));
          final row = prev['perJob'][j.id] as Map?;
          if (row != null) prevNet += (row['net'] ?? row['pay'] ?? 0) as num;
        } else {
          final ps = app.periodsAround(j, back: 1, forward: 0);
          if (ps.isNotEmpty) prevNet += app.estimateNetForPeriod(j, ps.first);
        }
      }
      final chartMax = max<double>(1, max(net, prevNet)) * 1.3;

      return Column(
        children: [
          SizedBox(height: height * .02),
          header,
          SizedBox(height: height * .01),
          CustomCard(
            color: ProjectColors.whiteColor,
            title: 'Combined — ${periodLabel(shift.projScope.value)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(
                  text: 'Hours: ${jobs.map((j) => '${j.name} ${shift.projHours[j.id]!.toStringAsFixed(0)}h').join('  •  ')}',
                  fontWeight: FontWeight.bold,
                  fontSize: .015,
                ),
                SizedBox(height: height * .04),
                Container(
                  height: height * .3,
                  color: Colors.transparent,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: chartMax,
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => textWidget(
                              text: v == 0 ? 'Projected' : 'Previous',
                              fontSize: .015,
                              color: ProjectColors.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: net, width: width * .04, color: Color(0xFF22C55E))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: prevNet, width: width * .04, color: const Color(0xFF9CA3AF))]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * .01),
                bullets([
                  'Gross ${money(gross)}',
                  'Net ${money(net)}',
                  'Income ${money(inc)}  •  CPP ${money(cp)}  •  EI ${money(ei)}  •  Other ${money(oth)}  •  Post-exp ${money(post)}',
                ]),
              ],
            ),
          ),
          for (final j in jobs)
            Padding(
              padding: EdgeInsets.only(top: height * .01),
              child: jobEstCard(j, estPerJob[j.id]!),
            ),
        ],
      );
    });
  }
}
