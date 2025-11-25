import 'dart:math';

import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Constant UI.dart';
import 'Overview.dart';

class DepositsTab extends StatelessWidget {
  const DepositsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const _MonthComparisonCard(),
          SizedBox(height: height * .018),
          const _MonthlyDepositsCard(),
          SizedBox(height: height * .018),
          const _WeeklyDepositsCard(),
          SizedBox(height: height * .024),
          textWidget(
            text: "By Job – November",
            fontSize: .02,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
          // TODO: plug your job list here
          SizedBox(height: height * .04),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// TOP BAR + MONTH HEADER
// ---------------------------------------------------------

class _TopNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Icon(
            Icons.chevron_left,
            size: height * .03,
            color: ProjectColors.whiteColor,
          ),
        ),
        SizedBox(width: width * .01),
        textWidget(
          text: "Calendar",
          fontSize: .017,
          color: ProjectColors.whiteColor.withOpacity(.65),
        ),
        SizedBox(width: width * .02),
        textWidget(
          text: "Deposits",
          fontSize: .017,
          color: ProjectColors.greenColor,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chevron_left,
            size: height * .026,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(width: width * .006),
          textWidget(
            text: "November 2025",
            fontSize: .02,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(width: width * .006),
          Icon(
            Icons.chevron_right,
            size: height * .026,
            color: ProjectColors.whiteColor.withOpacity(.4),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// REUSABLE CARD CONTAINER
// ---------------------------------------------------------

// ---------------------------------------------------------
// CARD 1 – MONTH VS PREVIOUS (LINE CHART)
// ---------------------------------------------------------

class _MonthComparisonCard extends StatelessWidget {
  const _MonthComparisonCard();

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: "November vs previous month",
            fontSize: .018,
            fontWeight: FontWeight.w500,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textWidget(
                text: "\$2,990",
                fontSize: .034,
                fontWeight: FontWeight.w700,
                color: ProjectColors.whiteColor,
              ),
              textWidget(
                text: "+21%",
                fontSize: .02,
                fontWeight: FontWeight.w600,
                color: ProjectColors.greenColor,
              ),
            ],
          ),
          SizedBox(height: height * .014),
          SizedBox(
            height: height * .13,
            child: Stack(
              children: [
                // Y labels
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(
                        text: "\$2,500",
                        fontSize: .012,
                        color: Colors.grey.shade500,
                      ),
                      textWidget(
                        text: "\$1,000",
                        fontSize: .012,
                        color: Colors.grey.shade500,
                      ),
                      textWidget(
                        text: "\$0",
                        fontSize: .012,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: width * .14),
                  child: CustomPaint(
                    painter: _LineChartPainter(),
                    size: Size(double.infinity, double.infinity),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * .006),
          Padding(
            padding: EdgeInsets.only(left: width * .14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _axisLabel("Jun"),
                _axisLabel("Jul"),
                _axisLabel("Aug"),
                _axisLabel("Sep"),
                _axisLabel("Oct"),
                _axisLabel("Nov"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisLabel(String text) => textWidget(
        text: text,
        fontSize: .013,
        color: Colors.grey.shade500,
      );
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(.06)
      ..strokeWidth = 1;

    // horizontal grid lines
    final gridCount = 3;
    for (int i = 0; i <= gridCount; i++) {
      final dy = size.height * i / gridCount;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // fake data points (relative 0–1)
    final points = <Offset>[];
    final values = [0.35, 0.4, 0.32, 0.34, 0.7, 0.9]; // Jun..Nov
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = stepX * i;
      final y = size.height * (1 - values[i]);
      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = ProjectColors.greenColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// CARD 2 – MONTHLY DEPOSITS (BAR CHART)
// ---------------------------------------------------------

class _MonthlyDepositsCard extends StatelessWidget {
  const _MonthlyDepositsCard();

  @override
  Widget build(BuildContext context) {
    final months = ["Jun", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final values = [0.3, 0.55, 0.7, 0.9, 1.0, 1.2]; // relative heights

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: "Monthly Deposits – Last 6 Months",
            fontSize: .018,
            fontWeight: FontWeight.w500,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .012),
          SizedBox(
            height: height * .14,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(
                        text: "\$1,500",
                        fontSize: .012,
                        color: Colors.grey.shade500,
                      ),
                      textWidget(
                        text: "\$1,000",
                        fontSize: .012,
                        color: Colors.grey.shade500,
                      ),
                      textWidget(
                        text: "\$0",
                        fontSize: .012,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: width * .14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(months.length, (i) {
                      return Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: width * .005,
                            ),
                            height: (height * .11) * values[i],
                            decoration: BoxDecoration(
                              color: ProjectColors.greenColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * .006),
          Padding(
            padding: EdgeInsets.only(left: width * .14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: months
                  .map((m) => textWidget(
                        text: m,
                        fontSize: .013,
                        color: Colors.grey.shade500,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// CARD 3 – WEEKLY DEPOSITS (DONUT + LABEL)
// ---------------------------------------------------------

class _WeeklyDepositsCard extends StatelessWidget {
  const _WeeklyDepositsCard();

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: "Weekly Deposits – November",
            fontSize: .018,
            fontWeight: FontWeight.w500,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .016),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: "DoorDash",
                      fontSize: .02,
                      fontWeight: FontWeight.w600,
                      color: ProjectColors.whiteColor,
                    ),
                    SizedBox(height: height * .004),
                    textWidget(
                      text: "Week",
                      fontSize: .015,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(height: height * .01),
                    textWidget(
                      text: "62%",
                      fontSize: .024,
                      fontWeight: FontWeight.w700,
                      color: ProjectColors.whiteColor,
                    ),
                    SizedBox(height: height * .004),
                    textWidget(
                      text: "of November deposits",
                      fontSize: .015,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: height * .1,
                width: height * .1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // outer ring
                    SizedBox(
                      height: height * .1,
                      width: height * .1,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade900,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    // main portion
                    SizedBox(
                      height: height * .1,
                      width: height * .1,
                      child: CircularProgressIndicator(
                        value: 0.62,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ProjectColors.greenColor,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Container(
                      height: height * .058,
                      width: height * .058,
                      decoration: BoxDecoration(
                        color: const Color(0xff101010),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: textWidget(
                        text: "Other",
                        fontSize: .013,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// class DepositsTab extends StatelessWidget {
//   const DepositsTab();
//
//   @override
//   Widget build(BuildContext context) {
//     // final app = Get.find<AppController>();
//     // final a = Get.find<DashboardState>();
//
//     return Obx(() {
//       // shift.initJobs(app.jobs.map((e) => e.id!));
//       // final selected = app.jobs.where((j) => shift.jobs.contains(j.id)).toList();
//
//       // Build timeline points (sorted by date)
//       final points = <DepositPoint>[];
//       void addJob(Job j) {
//         final ps = app.periodsAround(j, back: shift.depositLookBack!.value, forward: shift.depositLookForward!.value);
//         // for (final p in ps) {
//         //   final net = app.estimateNetForPeriod(j, p);
//         //   points.add(DepositPoint(p.deposit, net, j.id!));
//         // }
//       }
//
//       // for (final j in selected) {
//       //   addJob(j);
//       // }
//       points.sort((a, b) => a.d.compareTo(b.d));
//
//       final maxY = max<double>(1, points.fold(0, (m, e) => e.net > m ? e.net : m));
//
//       return Column(
//         children: [
//           SizedBox(height: height * .02),
//           CustomCard(
//             color: ProjectColors.whiteColor,
//             title: 'Filters',
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Wrap(spacing: 8, runSpacing: 8, children: [
//                   // for (final j in app.jobs)
//                   //   FilterChip(
//                   //     label: textWidget(text: j.name, fontSize: .015),
//                   //     selected: shift.jobs.contains(j.id),
//                   //     onSelected: (_) {
//                   //       if (shift.jobs.contains(j.id)) {
//                   //         shift.jobs.remove(j.id);
//                   //       } else {
//                   //         shift.jobs.add(j.id);
//                   //       }
//                   //     },
//                   //   ),
//                   // if (app.jobs.isNotEmpty)
//                   //   FilterChip(
//                   //     label: const Text('Both'),
//                   //     selected: shift.jobs.length == app.jobs.length,
//                   //     onSelected: (_) {
//                   //       shift.jobs
//                   //         ..clear()
//                   //         ..addAll(app.jobs.map((e) => e.id));
//                   //     },
//                   //   ),
//                 ]),
//                 SizedBox(height: height * .01),
//                 textWidget(text: 'Show:', fontSize: .015, fontWeight: FontWeight.bold),
//                 SizedBox(height: height * .01),
//                 Wrap(
//                   children: [
//                     seg<int>(
//                       value: shift.depositLookBack!.value,
//                       items: const {2: '2 back', 3: '3 back', 4: '4 back'},
//                       onChanged: (v) => shift.depositLookBack!.value = v,
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: height * .002),
//                 Wrap(
//                   children: [
//                     seg<int>(
//                       value: shift.depositLookForward!.value,
//                       items: const {2: '2 next', 3: '3 next', 4: '4 next'},
//                       onChanged: (v) => shift.depositLookForward!.value = v,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: height * .01),
//           CustomCard(
//             color: ProjectColors.whiteColor,
//             title: 'Upcoming & Recent Deposits',
//             child: AspectRatio(
//               aspectRatio: 16 / 7,
//               child: LineChart(
//                 LineChartData(
//                   minX: 0,
//                   maxX: (points.isEmpty ? 1 : points.length - 1).toDouble(),
//                   minY: 0,
//                   maxY: maxY * 1.25,
//                   titlesData: const FlTitlesData(
//                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   gridData: FlGridData(show: true),
//                   borderData: FlBorderData(show: false),
//                   lineBarsData: [
//                     // LineChartBarData(
//                     //   isCurved: true,
//                     //   barWidth: 3,
//                     //   color: const Color(0xFFFFFFFF),
//                     //   spots: [
//                     //     for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].net),
//                     //   ],
//                     //   dotData: FlDotData(
//                     //     show: true,
//                     //     getDotPainter: (s, __, ___, ____) {
//                     //       final idx = s.x.toInt();
//                     //       final job = app.jobs.firstWhereOrNull((e) => e.id == points[idx].job);
//                     //       return FlDotCirclePainter(
//                     //         color: app.jobColor(job?.colorHex ?? '#16a34a'),
//                     //         radius: 4,
//                     //         strokeColor: Colors.white,
//                     //         strokeWidth: 1,
//                     //       );
//                     //     },
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Per-job upcoming cards
//           // for (final j in selected) JobDepositRow(job: j),
//         ],
//       );
//     });
//   }
// }
//
// class DepositPoint {
//   final DateTime d;
//   final double net;
//   final String job;
//   DepositPoint(this.d, this.net, this.job);
// }
//
// class JobDepositRow extends StatelessWidget {
//   final Job job;
//   const JobDepositRow({required this.job});
//
//   @override
//   Widget build(BuildContext context) {
//     final periods = app.periodsAround(job, back: 0, forward: 2);
//     return Padding(
//       padding: EdgeInsets.only(top: height * .01),
//       // child: CustomCard(
//       //   title: job.name,
//       //   leading: CircleAvatar(radius: 6, backgroundColor: app.jobColor(job.colorHex!)),
//       //   child: SingleChildScrollView(
//       //     scrollDirection: Axis.horizontal,
//       //     child: Row(
//       //       children: [
//       //         for (final p in periods)
//       //           Container(
//       //             margin: EdgeInsets.only(right: width * .01),
//       //             padding: EdgeInsets.all(12),
//       //             width: width * .35,
//       //             decoration: BoxDecoration(
//       //               color: Color(0xFF121315),
//       //               borderRadius: BorderRadius.circular(14),
//       //               border: Border.all(color: const Color(0xFF232427)),
//       //             ),
//       //             child: Column(
//       //               crossAxisAlignment: CrossAxisAlignment.start,
//       //               children: [
//       //                 textWidget(text: '${md(p.start)} → ${md(p.end)}', fontSize: .015, color: ProjectColors.whiteColor),
//       //                 SizedBox(height: height * .01),
//       //                 Row(children: [
//       //                   Icon(Icons.money, size: height * .02, color: Color(0xFF16A34A)),
//       //                   SizedBox(width: width * .02),
//       //                   textWidget(text: money(app.estimateNetForPeriod(job, p)), fontSize: .015, color: ProjectColors.whiteColor),
//       //                 ]),
//       //                 SizedBox(height: height * .01),
//       //                 Row(children: [
//       //                   Icon(Icons.savings_outlined, size: height * .02, color: ProjectColors.whiteColor),
//       //                   SizedBox(width: width * .02),
//       //                   textWidget(text: 'Deposit: ${md(p.deposit)}', fontSize: .012, color: ProjectColors.whiteColor),
//       //                 ]),
//       //               ],
//       //             ),
//       //           ),
//       //       ],
//       //     ),
//       //   ),
//       // ),
//     );
//   }
// }
