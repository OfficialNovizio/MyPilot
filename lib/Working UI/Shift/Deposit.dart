import 'dart:math';

import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:get/get.dart';

class DepositsTab extends StatelessWidget {
  const DepositsTab();

  @override
  Widget build(BuildContext context) {
    // final app = Get.find<AppController>();
    // final a = Get.find<DashboardState>();

    return Obx(() {
      shift.initJobs(app.jobs.map((e) => e.id));
      final selected = app.jobs.where((j) => shift.jobs.contains(j.id)).toList();

      // Build timeline points (sorted by date)
      final points = <DepositPoint>[];
      void addJob(Job j) {
        final ps = app.periodsAround(j, back: shift.depositLookBack!.value, forward: shift.depositLookForward!.value);
        for (final p in ps) {
          final net = app.estimateNetForPeriod(j, p);
          points.add(DepositPoint(p.deposit, net, j.id));
        }
      }

      for (final j in selected) {
        addJob(j);
      }
      points.sort((a, b) => a.d.compareTo(b.d));

      final maxY = max<double>(1, points.fold(0, (m, e) => e.net > m ? e.net : m));

      return Column(
        children: [
          SizedBox(height: height * .02),
          Card(
            title: 'Filters',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final j in app.jobs)
                    FilterChip(
                      label: textWidget(text: j.name, fontSize: .015),
                      selected: shift.jobs.contains(j.id),
                      onSelected: (_) {
                        if (shift.jobs.contains(j.id)) {
                          shift.jobs.remove(j.id);
                        } else {
                          shift.jobs.add(j.id);
                        }
                      },
                    ),
                  if (app.jobs.isNotEmpty)
                    FilterChip(
                      label: const Text('Both'),
                      selected: shift.jobs.length == app.jobs.length,
                      onSelected: (_) {
                        shift.jobs
                          ..clear()
                          ..addAll(app.jobs.map((e) => e.id));
                      },
                    ),
                ]),
                SizedBox(height: height * .01),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    textWidget(text: 'Show:', fontSize: .015, fontWeight: FontWeight.bold),
                    SizedBox(width: width * .02),
                    seg<int>(
                      value: shift.depositLookBack!.value,
                      items: const {2: '2 back', 3: '3 back', 4: '4 back'},
                      onChanged: (v) => shift.depositLookBack!.value = v,
                    ),
                    SizedBox(width: width * .02),
                    seg<int>(
                      value: shift.depositLookForward!.value,
                      items: const {2: '2 next', 3: '3 next', 4: '4 next'},
                      onChanged: (v) => shift.depositLookForward!.value = v,
                    ),
                  ]),
                ),
              ],
            ),
          ),
          SizedBox(height: height * .01),
          Card(
            title: 'Upcoming & Recent Deposits',
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.isEmpty ? 1 : points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY * 1.25,
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFFFFFFFF),
                      spots: [
                        for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].net),
                      ],
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, __, ___, ____) {
                          final idx = s.x.toInt();
                          final job = app.jobs.firstWhereOrNull((e) => e.id == points[idx].job);
                          return FlDotCirclePainter(
                            color: app.jobColor(job?.colorHex ?? '#16a34a'),
                            radius: 4,
                            strokeColor: Colors.white,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Per-job upcoming cards
          for (final j in selected) JobDepositRow(job: j),
        ],
      );
    });
  }
}

class DepositPoint {
  final DateTime d;
  final double net;
  final String job;
  DepositPoint(this.d, this.net, this.job);
}

class JobDepositRow extends StatelessWidget {
  final Job job;
  const JobDepositRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final periods = app.periodsAround(job, back: 0, forward: 2);
    return Padding(
      padding: EdgeInsets.only(top: height * .01),
      child: Card(
        title: job.name,
        leading: CircleAvatar(radius: 6, backgroundColor: app.jobColor(job.colorHex)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final p in periods)
                Container(
                  margin: EdgeInsets.only(right: width * .01),
                  padding: EdgeInsets.all(12),
                  width: width * .35,
                  decoration: BoxDecoration(
                    color: Color(0xFF121315),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF232427)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(text: '${md(p.start)} → ${md(p.end)}', fontSize: .015, color: ProjectColors.whiteColor),
                      SizedBox(height: height * .01),
                      Row(children: [
                        Icon(Icons.money, size: height * .02, color: Color(0xFF16A34A)),
                        SizedBox(width: width * .02),
                        textWidget(text: money(app.estimateNetForPeriod(job, p)), fontSize: .015, color: ProjectColors.whiteColor),
                      ]),
                      SizedBox(height: height * .01),
                      Row(children: [
                        Icon(Icons.savings_outlined, size: height * .02, color: ProjectColors.whiteColor),
                        SizedBox(width: width * .02),
                        textWidget(text: 'Deposit: ${md(p.deposit)}', fontSize: .012, color: ProjectColors.whiteColor),
                      ]),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
