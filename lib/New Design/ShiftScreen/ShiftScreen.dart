// import 'dart:ui';
//
// import 'package:emptyproject/New%20Design/Constants.dart';
// import 'package:emptyproject/New%20Design/Controllers.dart';
// import 'package:emptyproject/New%20Design/ShiftScreen/ShiftScreen%20Getx.dart';
// import 'package:emptyproject/screens/salary_detailed_screen.dart';
// import 'package:emptyproject/utils/time_utils.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class ShiftScreen extends StatefulWidget {
//   const ShiftScreen({super.key});
//
//   @override
//   State<ShiftScreen> createState() => _ShiftScreenState();
// }
//
// class _ShiftScreenState extends State<ShiftScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Obx(
//       () => ClipRRect(
//         borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
//         child: ColoredBox(
//           color: ProjectColors.pureBlackColor,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TableCalendar(
//                   firstDay: DateTime(2020, 1, 1),
//                   lastDay: DateTime(2035, 12, 31),
//                   focusedDay: shift.focusedDay!.value,
//                   selectedDayPredicate: (d) => isSameDay(d, shift.selectedDay!.value),
//                   onDaySelected: (selected, focused) {
//                     shift.selectedDay!.value = selected;
//                     shift.focusedDay!.value = focused;
//
//                     shift.openDaySheet(selected);
//                   },
//                   calendarFormat: CalendarFormat.month,
//                   startingDayOfWeek: shift.settings.value.weekStartsOnMonday ? StartingDayOfWeek.monday : StartingDayOfWeek.sunday,
//                   headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
//                   calendarStyle: const CalendarStyle(
//                     outsideTextStyle: TextStyle(color: Colors.red),
//                     outsideDaysVisible: true,
//                     defaultTextStyle: TextStyle(color: Colors.green),
//                     todayDecoration: BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
//                     selectedDecoration: BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
//                     markersMaxCount: 4,
//                   ),
//                   eventLoader: (day) => shift.eventsForDay(day),
//                   calendarBuilders: CalendarBuilders(
//                     markerBuilder: (context, day, events) {
//                       if (events.isEmpty) return const SizedBox.shrink();
//                       final shifts = events.where((e) => (e as DayEvent).type == 'shift').cast<DayEvent>().toList();
//                       final stats = events.where((e) => (e as DayEvent).type == 'stat').cast<DayEvent>().toList();
//                       final pays = events.where((e) => (e as DayEvent).type == 'payday').cast<DayEvent>().toList();
//
//                       final dots = <Widget>[];
//                       for (final e in shifts.take(3)) {
//                         final job = shift.jobs.firstWhereOrNull((j) => j.id == e.jobId);
//                         dots.add(
//                           Container(
//                             width: 6,
//                             height: 6,
//                             margin: const EdgeInsets.symmetric(horizontal: 1.5),
//                             decoration: BoxDecoration(
//                               color: shift.jobColor(job?.colorHex ?? '#16a34a'),
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         );
//                       }
//
//                       // Payday badge follows job color
//                       Color paydayBg = Colors.green.shade700;
//                       Color paydayFg = Colors.white;
//                       if (pays.isNotEmpty) {
//                         final firstPay = pays.first;
//                         final job = shift.jobs.firstWhereOrNull((j) => j.id == firstPay.jobId);
//                         paydayBg = shift.jobColor(job?.colorHex ?? '#16a34a');
//                         paydayFg = paydayBg.computeLuminance() < 0.5 ? Colors.white : Colors.black;
//                       }
//
//                       return Stack(clipBehavior: Clip.none, children: [
//                         Positioned.fill(
//                           child: Align(
//                             alignment: Alignment.bottomCenter,
//                             child: Row(mainAxisSize: MainAxisSize.min, children: dots),
//                           ),
//                         ),
//                         if (pays.isNotEmpty)
//                           Positioned(
//                             right: -1,
//                             top: -2,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: paydayBg,
//                                 borderRadius: BorderRadius.circular(6),
//                                 border: Border.all(color: paydayFg.withOpacity(.25)),
//                               ),
//                               child: Text(
//                                 '\$',
//                                 style: TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                   color: paydayFg,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         if (stats.isNotEmpty)
//                           const Positioned(
//                             left: -1,
//                             top: -4,
//                             child: Icon(Icons.star, size: 10, color: Color(0xFFFFC107)),
//                           ),
//                       ]);
//                     },
//                   ),
//                 ),
//                 SizedBox(height: height * .02),
//                 MonthSummary(month: shift.focusedDay!.value),
//                 SizedBox(height: height * .02),
//                 PayPeriods(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class PayPeriods extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         for (final j in shift.jobs) JobPeriods(jid: j.id),
//       ],
//     );
//   }
// }
//
// class JobPeriods extends StatelessWidget {
//   final String jid;
//   const JobPeriods({required this.jid});
//
//   @override
//   Widget build(BuildContext context) {
//     final j = shift.jobs.firstWhere((x) => x.id == jid);
//     final series = shift.periodsAround(j, back: 0, forward: 2);
//     final next = shift.nextDeposit(j);
//     return Container(
//       decoration: BoxDecoration(
//         color: ProjectColors.greenColor,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       margin: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .01),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               CircleAvatar(backgroundColor: shift.jobColor(j.colorHex), radius: height * .01),
//               SizedBox(width: height * .01),
//               textWidget(
//                 text: "${j.name} — ${j.payFrequency == "biweekly" ? "Biweekly" : "Weekly"}",
//                 fontSize: .02,
//                 fontWeight: FontWeight.bold,
//               ),
//               const Spacer(),
//               if (next != null)
//                 textWidget(
//                     text: "Next deposit: ${monthDay(next)} "
//                         "${next.hour.toString().padLeft(2, '0')}:"
//                         "${next.minute.toString().padLeft(2, '0')}",
//                     color: Colors.red),
//             ]),
//             SizedBox(height: height * .01),
//             SingleJobSeriesChart(
//               jobId: 'starbucks',
//               metric: SeriesMetric.hours,
//               mode: TimelineMode.month,
//             ),
//             // Column(
//             //   children: [
//             //     for (final p in series)
//             //       Padding(
//             //         padding: EdgeInsets.only(bottom: height * .01),
//             //         child: PeriodRow(period: p),
//             //       ),
//             //   ],
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class PeriodRow extends StatelessWidget {
//   final dynamic period;
//   const PeriodRow({required this.period});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF121315),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF232427)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "${monthDay(period.start)} → ${monthDay(period.end)}",
//                   style: const TextStyle(fontWeight: FontWeight.w600,color: Colors.white),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   "Hours: ${period.hours.toStringAsFixed(2)}   •   OT: ${period.overtime.toStringAsFixed(2)}",
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               const Text("Est. Cheque", style: TextStyle(fontSize: 12, color: Colors.grey)),
//               Text(
//                 "\$${period.pay.toStringAsFixed(2)}",
//                 style: const TextStyle(fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 6),
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.attach_money, size: 14, color: Color(0xFF16A34A)),
//                   const SizedBox(width: 4),
//                   Text(
//                     "Deposit: ${monthDay(period.deposit)}",
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class MonthSummary extends StatelessWidget {
//   final DateTime month;
//   const MonthSummary({required this.month});
//
//   @override
//   Widget build(BuildContext context) {
//     final perJob = shift.monthSummary(month);
//     final combined = perJob.values.fold<Map<String, double>>(
//       {'hours': 0.0, 'pay': 0.0},
//       (a, b) {
//         a['hours'] = (a['hours'] ?? 0) + (b['hours'] ?? 0);
//         a['pay'] = (a['pay'] ?? 0) + (b['pay'] ?? 0);
//         return a;
//       },
//     );
//     return GestureDetector(
//       onTap: () => Get.to(
//         () => SalaryDetailsScreen(month: month),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: ProjectColors.greenColor,
//           borderRadius: BorderRadius.circular(30),
//         ),
//         margin: EdgeInsets.symmetric(horizontal: width * .02),
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 textWidget(text: "Month Summary", fontSize: .02, fontWeight: FontWeight.bold),
//                 textWidget(
//                     text: "Combined: ${(combined['hours'] ?? 0).toStringAsFixed(1)} h • \$${(combined['pay'] ?? 0).toStringAsFixed(2)}",
//                     fontSize: .015,
//                     fontWeight: FontWeight.bold),
//               ],
//             ),
//             textWidget(text: "${month.month}/${month.year}", fontSize: .02, fontWeight: FontWeight.bold),
//             SizedBox(height: height * .01),
//             for (final j in shift.jobs)
//               Padding(
//                 padding: EdgeInsets.only(top: height * .01),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         CircleAvatar(backgroundColor: shift.jobColor(j.colorHex), radius: height * .01),
//                         SizedBox(width: width * .02),
//                         textWidget(text: j.name, fontSize: .02, fontWeight: FontWeight.w400),
//                       ],
//                     ),
//                     textWidget(
//                         text: '${(perJob[j.id]!['hours'] ?? 0.0).toStringAsFixed(1)} h   •   \$${(perJob[j.id]!['pay'] ?? 0.0).toStringAsFixed(2)}',
//                         fontSize: .02,
//                         fontWeight: FontWeight.w400),
//                   ],
//                 ),
//               ),
//           ]),
//         ),
//       ),
//     );
//   }
// }
//
// /// Which value to plot
// enum SeriesMetric { hours, net }
//
// /// Which window to show from the job's full history
// enum TimelineMode { week, biweek, month, all }
//
// class SingleJobSeriesChart extends StatefulWidget {
//   final String jobId;
//   final SeriesMetric metric;
//   final TimelineMode mode;
//
//   /// Max periods to look back from the most recent (kept high enough for “all”).
//   final int maxBack;
//
//   const SingleJobSeriesChart({
//     super.key,
//     required this.jobId,
//     this.metric = SeriesMetric.hours,
//     this.mode = TimelineMode.month,
//     this.maxBack = 64,
//   });
//
//   @override
//   State<SingleJobSeriesChart> createState() => _SingleJobSeriesChartState();
// }
//
// class _SingleJobSeriesChartState extends State<SingleJobSeriesChart> {
//   double? _touchedX; // for the vertical dashed guide
//
//   @override
//   Widget build(BuildContext context) {
//     final j = shift.jobs.firstWhere((e) => e.id == widget.jobId);
//
//     // 1) Collect many periods for this job (chronological)
//     final periods = shift
//         .periodsAround(j, back: widget.maxBack, forward: 0)
//         .reversed
//         .toList();
//
//     // 2) Filter by timeline window
//     final now = DateTime.now();
//     final days = switch (widget.mode) {
//       TimelineMode.week   => 7,
//       TimelineMode.biweek => 14,
//       TimelineMode.month  => 31,
//       TimelineMode.all    => 10000, // "effectively all"
//     };
//
//     final filtered = periods.where((p) {
//       final cutoff = now.subtract(Duration(days: days));
//       return widget.mode == TimelineMode.all || !p.deposit.isBefore(cutoff);
//     }).toList();
//
//     // Safety
//     if (filtered.isEmpty) {
//       return _CardShell(
//         title: _title(j.name),
//         child: const SizedBox(
//           height: 220,
//           child: Center(child: Text('No data yet')),
//         ),
//       );
//     }
//
//     // 3) Build points (x=index, y=value)
//     final spots = <FlSpot>[];
//     final labels = <String>[];
//
//     for (int i = 0; i < filtered.length; i++) {
//       final p = filtered[i];
//       final y = (widget.metric == SeriesMetric.hours)
//           ? p.hours
//           : shift.estimateNetForPeriod(j, p);
//       spots.add(FlSpot(i.toDouble(), y));
//       labels.add(_md(p.deposit));
//     }
//
//     // Scaling
//     final double maxY = spots
//         .fold<double>(0, (m, s) => s.y > m ? s.y : m)
//         .clamp(1, double.infinity)
//         .toDouble();
//
// // 2) keep the guide line X as a double
//     final double guideX = ((_touchedX ?? -1)
//         .clamp(0, (spots.length - 1).toDouble()))
//         .toDouble();
//
//     // A green gradient very close to your reference
//     const topGreen  = Color(0xFF22C55E);
//     const midGreen  = Color(0xFF16A34A);
//     const darkGreen = Color(0xFF0B2B15);
//
//     // Vertical guide line position (kept inside range)
//
//     return _CardShell(
//       title: _title(j.name),
//       child: SizedBox(
//         height: 240,
//         child: LineChart(
//           LineChartData(
//             minX: 0,
//             maxX: (spots.length - 1).toDouble(),
//             minY: 0,
//             maxY: maxY * 1.20,
//             backgroundColor: Colors.transparent,
//             borderData: FlBorderData(show: false),
//             gridData: FlGridData(
//               show: true,
//               drawVerticalLine: false,
//               getDrawingHorizontalLine: (value) => FlLine(
//                 color: Colors.white.withOpacity(.08),
//                 strokeWidth: 1,
//                 dashArray: [4, 6],
//               ),
//             ),
//             titlesData: FlTitlesData(
//               topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               leftTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   reservedSize: 36,
//                   getTitlesWidget: (v, _) =>
//                       Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.white70)),
//                 ),
//               ),
//               bottomTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   reservedSize: 26,
//                   getTitlesWidget: (v, _) {
//                     final i = v.toInt();
//                     if (i < 0 || i >= labels.length) return const SizedBox.shrink();
//                     return Padding(
//                       padding: const EdgeInsets.only(top: 6),
//                       child: Text(labels[i], style: const TextStyle(fontSize: 10, color: Colors.white70)),
//                     );
//                   },
//                 ),
//               ),
//             ),
//
//             // Extra vertical guide line (dashed) at touched X
//             extraLinesData: _touchedX == null
//                 ? const ExtraLinesData()
//                 : ExtraLinesData(
//               verticalLines: [
//                 VerticalLine(
//                   x: guideX,
//                   color: Colors.white,
//                   strokeWidth: 1,
//                   dashArray: [2, 6],
//                 ),
//               ],
//             ),
//
//             lineTouchData: LineTouchData(
//               handleBuiltInTouches: true,
//               touchCallback: (evt, resp) {
//                 setState(() {
//                   _touchedX = resp?.lineBarSpots?.isNotEmpty == true
//                       ? resp!.lineBarSpots!.first.x
//                       : null;
//                 });
//               },
//               touchTooltipData: LineTouchTooltipData(
//                 tooltipBgColor: Colors.black.withOpacity(.85),
//                 fitInsideHorizontally: true,
//                 fitInsideVertically: true,
//                 getTooltipItems: (touchedSpots) {
//                   return touchedSpots.map((s) {
//                     final v = s.y;
//                     final txt = widget.metric == SeriesMetric.hours
//                         ? v.toStringAsFixed(0)
//                         : '\$${v.toStringAsFixed(0)}';
//                     return LineTooltipItem(
//                       txt,
//                       const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     );
//                   }).toList();
//                 },
//               ),
//             ),
//
//             lineBarsData: [
//               LineChartBarData(
//                 spots: spots,
//                 isCurved: true,
//                 barWidth: 3,
//                 color: topGreen,
//                 dotData: FlDotData(
//                   show: true,
//                   getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
//                     radius: 3.5,
//                     color: Colors.white,
//                     strokeColor: Colors.white,
//                     strokeWidth: 1.2,
//                   ),
//                 ),
//                 belowBarData: BarAreaData(
//                   show: true,
//                   gradient: const LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       topGreen,
//                       midGreen,
//                       darkGreen,
//                       Colors.transparent,
//                     ],
//                     stops: [0.0, 0.28, 0.55, 1.0],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _title(String jobName) {
//     final metricLabel = (widget.metric == SeriesMetric.hours) ? 'Hours' : 'Net';
//     final window = switch (widget.mode) {
//       TimelineMode.week   => 'Last 7d',
//       TimelineMode.biweek => 'Last 14d',
//       TimelineMode.month  => 'Last 30d',
//       TimelineMode.all    => 'All time',
//     };
//     return '$jobName — $metricLabel ($window)';
//   }
//
//   String _md(DateTime d) => '${d.day} ${_mon[d.month - 1]}';
// }
//
// const _mon = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
//
// /* ------------ tiny card shell to match your dark UI ------------------ */
//
// class _CardShell extends StatelessWidget {
//   final String title;
//   final Widget child;
//   const _CardShell({required this.title, required this.child});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF101214),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFF232527)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
//           ]),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }
// }